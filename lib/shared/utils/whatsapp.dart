import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre o WhatsApp com [text] para o telefone do aluno.
/// Número brasileiro sem DDI recebe o 55 na frente.
Future<void> openWhatsApp(BuildContext context, String? phone, String text) async {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cadastre o telefone do aluno para usar o WhatsApp.'),
    ));
    return;
  }
  final number = digits.length <= 11 ? '55$digits' : digits;
  await launchUrl(
    Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(text)}'),
    mode: LaunchMode.externalApplication,
  );
}

/// Primeiro nome, para mensagens.
String firstName(String name) => name.trim().split(RegExp(r'\s+')).first;
