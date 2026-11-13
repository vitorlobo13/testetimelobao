import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:time_lobao/shared/widgets/avatar_crop_dialog.dart';

/// Foto 400x200: metade esquerda vermelha, direita azul.
img.Image _photo() {
  final p = img.Image(width: 400, height: 200);
  for (var y = 0; y < 200; y++) {
    for (var x = 0; x < 400; x++) {
      p.setPixelRgb(x, y, x < 200 ? 255 : 0, 0, x < 200 ? 0 : 255);
    }
  }
  return p;
}

img.Image _run(Matrix4 m) => img.decodeJpg(
    cropAvatar(source: _photo(), viewport: 100, matrix: m, outputSize: 64))!;

void main() {
  test('sem mexer, recorta o quadrado do centro', () {
    final out = _run(Matrix4.identity());
    expect(out.width, 64);
    expect(out.height, 64);
    // Centro da foto fica no centro: esquerda vermelha, direita azul.
    expect(out.getPixel(5, 32).r, greaterThan(200));
    expect(out.getPixel(58, 32).b, greaterThan(200));
  });

  test('arrastar para a direita mostra o lado esquerdo da foto', () {
    // Cover: foto vira 200x100 no quadro de 100, sobrando 50 de cada lado.
    final m = Matrix4.identity()..translateByDouble(50, 0, 0, 1);
    final out = _run(m);
    expect(out.getPixel(32, 32).r, greaterThan(200));
    expect(out.getPixel(32, 32).b, lessThan(60));
  });

  test('zoom 2x no canto superior direito', () {
    final m = Matrix4.identity()
      ..translateByDouble(-100, 0, 0, 1)
      ..scaleByDouble(2, 2, 1, 1);
    final out = _run(m);
    expect(out.getPixel(32, 32).b, greaterThan(200));
  });
}
