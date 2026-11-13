import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void setBrowserThemeColor(Color color) {
  final hex =
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  var meta = web.document.querySelector('meta[name="theme-color"]');
  if (meta == null) {
    meta = web.document.createElement('meta')
      ..setAttribute('name', 'theme-color');
    web.document.head?.append(meta);
  }
  meta.setAttribute('content', hex);
  web.document.documentElement?.setAttribute('style', 'background: $hex');
  web.document.body?.style.background = hex;
}

void reloadPage() => web.window.location.reload();
