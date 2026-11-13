import 'package:flutter/material.dart';

import 'browser_theme_color_stub.dart'
    if (dart.library.js_interop) 'browser_theme_color_web.dart' as impl;

/// Pinta a faixa do topo do celular (hora, bateria) e o fundo da página com
/// a cor do visual atual. Só faz algo na web; no app nativo não faz nada.
void setBrowserThemeColor(Color color) => impl.setBrowserThemeColor(color);

/// Recarrega a página (só na web). O iPhone só lê a cor da faixa do topo ao
/// carregar o app, então recarregar é o jeito de ela trocar na hora.
void reloadPage() => impl.reloadPage();
