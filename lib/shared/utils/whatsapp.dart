import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Só os dígitos, com 55 na frente quando é número brasileiro sem DDI.
/// Vazio quando não há telefone (o WhatsApp pergunta para quem enviar).
String whatsAppNumber(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  return digits.length <= 11 ? '55$digits' : digits;
}

/// Endereço que abre o WhatsApp com a mensagem pronta.
/// No iPhone usa o endereço próprio do WhatsApp (`whatsapp://`): o
/// endereço `wa.me` abria um navegador por cima do app que ficava numa
/// página em branco depois de passar para o WhatsApp.
Uri whatsAppUri(String number, String text, {required bool iOS}) {
  final encoded = Uri.encodeComponent(text);
  if (iOS) {
    final to = number.isEmpty ? '' : 'phone=$number&';
    return Uri.parse('whatsapp://send?${to}text=$encoded');
  }
  return Uri.parse('https://wa.me/$number?text=$encoded');
}

/// Abre o WhatsApp com [text] para [phone] (pode ser vazio).
Future<void> launchWhatsApp(String? phone, String text) async {
  final iOS = defaultTargetPlatform == TargetPlatform.iOS;
  final uri = whatsAppUri(whatsAppNumber(phone), text, iOS: iOS);
  if (iOS && kIsWeb) {
    // Mesma janela: o iPhone passa para o WhatsApp e o app fica onde estava.
    await launchUrl(uri, webOnlyWindowName: '_self');
  } else {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Abre o WhatsApp com [text] para o telefone do aluno.
Future<void> openWhatsApp(
    BuildContext context, String? phone, String text) async {
  if (whatsAppNumber(phone).isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cadastre o telefone do aluno para usar o WhatsApp.'),
    ));
    return;
  }
  await launchWhatsApp(phone, text);
}

/// Primeiro nome, para mensagens.
String firstName(String name) => name.trim().split(RegExp(r'\s+')).first;
