import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Endereço público do app, usado nos links de convite fora da web.
const String kPublicAppUrl = 'https://testetimelobao.vercel.app';

class InviteLink {
  const InviteLink({required this.url, required this.expiresAt});
  final String url;
  final DateTime expiresAt;
}

class InviteInfo {
  const InviteInfo({
    required this.valid,
    this.reason,
    this.trainerName,
    this.studentName,
    this.email,
  });

  final bool valid;
  final String? reason;
  final String? trainerName;
  final String? studentName;
  final String? email;
}

/// Convites de aluno. Tudo passa por Cloud Functions: a coleção `invites`
/// é fechada para leitura/escrita direta.
class InviteRepository {
  InviteRepository({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  static String get _baseUrl => kIsWeb ? Uri.base.origin : kPublicAppUrl;

  /// Gera um link novo (vale 7 dias) para o aluno pendente.
  Future<InviteLink> createInvite(String linkId) async {
    final result = await _functions
        .httpsCallable('createStudentInvite')
        .call<Map<String, dynamic>>({'linkId': linkId});
    final data = Map<String, dynamic>.from(result.data);
    return InviteLink(
      url: '$_baseUrl/convite/${data['token']}',
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Future<InviteInfo> getInvite(String token) async {
    final result = await _functions
        .httpsCallable('getInvite')
        .call<Map<String, dynamic>>({'token': token});
    final d = Map<String, dynamic>.from(result.data);
    return InviteInfo(
      valid: d['valid'] == true,
      reason: d['reason'] as String?,
      trainerName: d['trainerName'] as String?,
      studentName: d['studentName'] as String?,
      email: d['email'] as String?,
    );
  }

  Future<void> accept(String token) => _functions
      .httpsCallable('acceptStudentInvite')
      .call<void>({'token': token});
}
