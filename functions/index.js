/**
 * Cloud Functions do Time Lobão.
 *
 * Tudo que define o PAPEL de uma conta (admin / trainer / student) passa
 * por aqui: o app nunca grava papel direto. O papel fica no custom claim
 * `role` do Firebase Auth e é copiado em users/{uid} só para exibição.
 */
const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({region: "southamerica-east1", maxInstances: 5});

const db = admin.firestore();
const auth = admin.auth();
const {FieldValue} = admin.firestore;

/** E-mails (separados por vírgula, em functions/.env) que podem virar a conta admin. */
const adminEmails = () => (process.env.ADMIN_EMAILS || "");

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Faça login para continuar.");
  }
  return request.auth;
}

function requireAdmin(request) {
  const caller = requireAuth(request);
  if (caller.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Apenas a conta admin pode fazer isso.");
  }
  return caller;
}

function cleanString(value, field, {min = 1, max = 120} = {}) {
  if (typeof value !== "string" || value.trim().length < min || value.trim().length > max) {
    throw new HttpsError("invalid-argument", `Campo "${field}" inválido.`);
  }
  return value.trim();
}

/**
 * Cadastro avulso (fase de teste): a pessoa escolhe personal ou aluno.
 * Bloqueado quando o admin desliga config/app.allowSelfSignup.
 */
exports.completeSelfSignup = onCall(async (request) => {
  const caller = requireAuth(request);
  const name = cleanString(request.data?.name, "name", {min: 2});
  const role = request.data?.role;
  if (!["trainer", "student"].includes(role)) {
    throw new HttpsError("invalid-argument", "Perfil inválido.");
  }

  const user = await auth.getUser(caller.uid);
  if (user.customClaims?.role) {
    throw new HttpsError("already-exists", "Esta conta já tem um perfil.");
  }

  const config = await db.doc("config/app").get();
  const allowSelfSignup = config.exists ? config.get("allowSelfSignup") !== false : true;
  if (!allowSelfSignup) {
    throw new HttpsError(
        "failed-precondition",
        "O cadastro está fechado. Peça um convite ao seu personal.",
    );
  }

  await auth.setCustomUserClaims(caller.uid, {role});
  await db.doc(`users/${caller.uid}`).set({
    name,
    email: user.email,
    role,
    active: true,
    source: "self-signup",
    createdAt: FieldValue.serverTimestamp(),
  });
  return {role};
});

/**
 * A conta admin é criada à mão no console do Firebase. No primeiro login o
 * app chama esta função, que só concede o papel se o e-mail estiver em
 * ADMIN_EMAILS (functions/.env).
 */
exports.claimAdmin = onCall(async (request) => {
  const caller = requireAuth(request);
  const allowed = adminEmails()
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean);
  const email = (caller.token.email || "").toLowerCase();
  if (!email || !allowed.includes(email)) {
    throw new HttpsError("permission-denied", "Conta sem acesso liberado.");
  }

  const user = await auth.getUser(caller.uid);
  if (user.customClaims?.role && user.customClaims.role !== "admin") {
    throw new HttpsError("already-exists", "Esta conta já tem outro perfil.");
  }

  await auth.setCustomUserClaims(caller.uid, {role: "admin"});
  await db.doc(`users/${caller.uid}`).set({
    name: "Administrador",
    email: user.email,
    role: "admin",
    active: true,
    createdAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {role: "admin"};
});

/**
 * Admin convida um personal: cria a conta (sem senha) ou reaproveita uma
 * existente sem papel. O app em seguida pede ao Firebase o e-mail de
 * "defina sua senha".
 */
exports.inviteTrainer = onCall(async (request) => {
  requireAdmin(request);
  const name = cleanString(request.data?.name, "name", {min: 2});
  const email = cleanString(request.data?.email, "email", {min: 5}).toLowerCase();

  let user;
  try {
    user = await auth.getUserByEmail(email);
    const currentRole = user.customClaims?.role;
    if (currentRole && currentRole !== "trainer") {
      throw new HttpsError(
          "already-exists",
          `Este e-mail já está em uso como ${currentRole === "student" ? "aluno" : currentRole}.`,
      );
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error.code !== "auth/user-not-found") throw error;
    user = await auth.createUser({email, displayName: name});
  }

  await auth.updateUser(user.uid, {disabled: false});
  await auth.setCustomUserClaims(user.uid, {role: "trainer"});
  await db.doc(`users/${user.uid}`).set({
    name,
    email,
    role: "trainer",
    active: true,
    source: "invite",
    invitedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {uid: user.uid};
});

/** Admin ativa/desativa um personal (desativado não consegue logar). */
exports.setTrainerActive = onCall(async (request) => {
  requireAdmin(request);
  const uid = cleanString(request.data?.uid, "uid");
  const active = request.data?.active === true;

  const user = await auth.getUser(uid);
  if (user.customClaims?.role !== "trainer") {
    throw new HttpsError("failed-precondition", "Esta conta não é de personal.");
  }

  await auth.updateUser(uid, {disabled: !active});
  if (!active) await auth.revokeRefreshTokens(uid);
  await db.doc(`users/${uid}`).set({active}, {merge: true});
  return {active};
});

// ---------------------------------------------------------------------------
// Alunos: convite por link, aceite e exclusão com dados
// ---------------------------------------------------------------------------

const crypto = require("crypto");
const INVITE_DAYS = 7;

async function requireOwnLink(request, linkId) {
  const caller = requireAuth(request);
  if (caller.token.role !== "trainer") {
    throw new HttpsError("permission-denied", "Apenas personais podem fazer isso.");
  }
  const ref = db.doc(`studentLinks/${cleanString(linkId, "linkId")}`);
  const snap = await ref.get();
  if (!snap.exists || snap.get("trainerId") !== caller.uid) {
    throw new HttpsError("not-found", "Aluno não encontrado.");
  }
  return {caller, ref, snap};
}

/** Personal gera (ou renova) o link de convite de um aluno pendente. */
exports.createStudentInvite = onCall(async (request) => {
  const {caller, ref, snap} = await requireOwnLink(request, request.data?.linkId);
  if (snap.get("studentUid")) {
    throw new HttpsError("failed-precondition", "Este aluno já aceitou o convite.");
  }

  const trainer = await db.doc(`users/${caller.uid}`).get();
  const token = crypto.randomBytes(18).toString("base64url");
  const expiresAt = new Date(Date.now() + INVITE_DAYS * 24 * 60 * 60 * 1000);

  await db.doc(`invites/${token}`).set({
    type: "student",
    linkId: ref.id,
    trainerId: caller.uid,
    trainerName: trainer.get("name") || "Seu personal",
    studentName: snap.get("name") || "",
    email: snap.get("email") || "",
    expiresAt,
    usedAt: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  await ref.update({lastInviteAt: FieldValue.serverTimestamp()});
  return {token, expiresAt: expiresAt.toISOString()};
});

/** Dados públicos do convite, para a tela de aceite (sem login). */
exports.getInvite = onCall(async (request) => {
  const token = cleanString(request.data?.token, "token", {min: 10});
  const snap = await db.doc(`invites/${token}`).get();
  if (!snap.exists || snap.get("type") !== "student") {
    return {valid: false, reason: "Convite não encontrado."};
  }
  if (snap.get("usedAt")) return {valid: false, reason: "Este convite já foi usado."};
  if (snap.get("expiresAt").toDate() < new Date()) {
    return {valid: false, reason: "Este convite expirou. Peça um novo ao seu personal."};
  }
  return {
    valid: true,
    trainerName: snap.get("trainerName"),
    studentName: snap.get("studentName"),
    email: snap.get("email"),
  };
});

/**
 * Aluno logado aceita o convite: vira "student" (se ainda não tinha papel),
 * o vínculo fica ativo e qualquer vínculo ativo anterior com outro personal
 * é arquivado — o histórico fica com o personal antigo.
 */
exports.acceptStudentInvite = onCall(async (request) => {
  const caller = requireAuth(request);
  const token = cleanString(request.data?.token, "token", {min: 10});

  const user = await auth.getUser(caller.uid);
  const currentRole = user.customClaims?.role;
  if (currentRole && currentRole !== "student") {
    throw new HttpsError(
        "failed-precondition",
        "Esta conta é de personal/admin. Use outro e-mail para entrar como aluno.",
    );
  }

  const inviteRef = db.doc(`invites/${token}`);
  const linkId = await db.runTransaction(async (tx) => {
    const invite = await tx.get(inviteRef);
    if (!invite.exists || invite.get("type") !== "student") {
      throw new HttpsError("not-found", "Convite não encontrado.");
    }
    if (invite.get("usedAt")) {
      throw new HttpsError("failed-precondition", "Este convite já foi usado.");
    }
    if (invite.get("expiresAt").toDate() < new Date()) {
      throw new HttpsError("failed-precondition", "Este convite expirou.");
    }

    const linkRef = db.doc(`studentLinks/${invite.get("linkId")}`);
    const link = await tx.get(linkRef);
    if (!link.exists || link.get("studentUid")) {
      throw new HttpsError("failed-precondition", "Este convite não está mais disponível.");
    }

    const previous = await tx.get(db.collection("studentLinks")
        .where("studentUid", "==", caller.uid)
        .where("linkStatus", "==", "active"));

    previous.docs.forEach((doc) => tx.update(doc.ref, {
      linkStatus: "archived",
      isActive: false,
      status: "inactive",
      archivedAt: FieldValue.serverTimestamp(),
    }));
    tx.update(linkRef, {
      studentUid: caller.uid,
      linkStatus: "active",
      acceptedAt: FieldValue.serverTimestamp(),
    });
    tx.update(inviteRef, {usedAt: FieldValue.serverTimestamp(), usedBy: caller.uid});
    tx.set(db.doc(`users/${caller.uid}`), {
      name: user.displayName || link.get("name") || "",
      email: user.email,
      role: "student",
      active: true,
      createdAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return linkRef.id;
  });

  if (!currentRole) await auth.setCustomUserClaims(caller.uid, {role: "student"});
  return {linkId};
});

/** Personal exclui o aluno e todos os dados dele (subcoleções incluídas). */
exports.deleteStudentLink = onCall(async (request) => {
  const {ref} = await requireOwnLink(request, request.data?.linkId);
  const invites = await db.collection("invites").where("linkId", "==", ref.id).get();
  await Promise.all(invites.docs.map((d) => d.ref.delete()));
  await db.recursiveDelete(ref);
  return {deleted: true};
});

// ---------------------------------------------------------------------------
// Notificações: treino concluído (para o personal) e treino novo (para o aluno)
// ---------------------------------------------------------------------------

const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");

/** Grava a notificação no app e tenta mandar push para os aparelhos. */
async function notifyUser(uid, {title, body, type, data = {}}) {
  if (!uid) return;
  await db.collection(`users/${uid}/notifications`).add({
    title,
    body,
    type,
    data,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  const tokensSnap = await db.collection(`users/${uid}/fcmTokens`).get();
  const tokens = tokensSnap.docs.map((d) => d.id);
  if (tokens.length === 0) return;

  const result = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data: {type, ...Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)]))},
    webpush: {fcmOptions: {link: "/"}},
  });
  // Remove tokens de aparelhos que não existem mais.
  await Promise.all(result.responses.map((r, i) => {
    const code = r.error?.code || "";
    if (code.includes("registration-token-not-registered") ||
        code.includes("invalid-registration-token")) {
      return db.doc(`users/${uid}/fcmTokens/${tokens[i]}`).delete();
    }
    return null;
  }));
}

/** Aluno concluiu um treino: atualiza o vínculo e avisa o personal. */
exports.onSessionWritten = onDocumentWritten(
    "studentLinks/{linkId}/sessions/{sessionId}",
    async (event) => {
      const before = event.data?.before?.data();
      const after = event.data?.after?.data();
      if (!after || !after.completed || before?.completed) return;

      const linkRef = db.doc(`studentLinks/${event.params.linkId}`);
      const link = await linkRef.get();
      if (!link.exists) return;

      await linkRef.update({
        lastWorkoutDate: after.endTime || FieldValue.serverTimestamp(),
        totalWorkouts: FieldValue.increment(1),
      });

      const studentName = link.get("name") || "Seu aluno";
      const division = after.divisionName || after.workoutName || "o treino";
      const minutes = after.durationMinutes ? ` em ${after.durationMinutes} min` : "";
      try {
        await notifyUser(link.get("trainerId"), {
          title: `${studentName} concluiu o treino 💪`,
          body: `${division}${minutes}.`,
          type: "session_completed",
          data: {linkId: link.id, sessionId: event.params.sessionId},
        });
      } catch (error) {
        logger.error("Falha ao notificar personal", error);
      }
    },
);

/** Personal prescreveu um treino novo: avisa o aluno. */
exports.onWorkoutWritten = onDocumentWritten(
    "studentLinks/{linkId}/workouts/{workoutId}",
    async (event) => {
      const before = event.data?.before?.data();
      const after = event.data?.after?.data();
      if (!after || !after.isActive || before?.isActive) return;

      const link = await db.doc(`studentLinks/${event.params.linkId}`).get();
      const studentUid = link.get("studentUid");
      if (!studentUid || link.get("linkStatus") !== "active") return;

      const trainer = await db.doc(`users/${link.get("trainerId")}`).get();
      try {
        await notifyUser(studentUid, {
          title: "Treino novo disponível",
          body: `${trainer.get("name") || "Seu personal"} preparou "${after.name}" para você.`,
          type: "workout_assigned",
          data: {workoutId: event.params.workoutId},
        });
      } catch (error) {
        logger.error("Falha ao notificar aluno", error);
      }
    },
);
