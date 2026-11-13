import 'package:flutter_test/flutter_test.dart';
import 'package:time_lobao/shared/utils/whatsapp.dart';

void main() {
  test('número brasileiro ganha o 55', () {
    expect(whatsAppNumber('(11) 98888-7777'), '5511988887777');
    expect(whatsAppNumber('5511988887777'), '5511988887777');
    expect(whatsAppNumber(null), '');
  });

  test('iPhone usa whatsapp://, os outros wa.me', () {
    expect(whatsAppUri('5511988887777', 'Oi João', iOS: true).toString(),
        'whatsapp://send?phone=5511988887777&text=Oi%20Jo%C3%A3o');
    expect(
        whatsAppUri('', 'Oi', iOS: true).toString(), 'whatsapp://send?text=Oi');
    expect(whatsAppUri('5511988887777', 'Oi', iOS: false).toString(),
        'https://wa.me/5511988887777?text=Oi');
  });
}
