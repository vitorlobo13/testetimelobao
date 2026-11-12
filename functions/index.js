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
