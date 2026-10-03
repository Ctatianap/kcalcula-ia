import 'package:calorias_ia/features/diary/diary_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AC2: saludo según la hora', () {
    expect(greetingFor(DateTime(2026, 10, 3, 5)), 'Buenos días');
    expect(greetingFor(DateTime(2026, 10, 3, 11, 59)), 'Buenos días');
    expect(greetingFor(DateTime(2026, 10, 3, 12)), 'Buenas tardes');
    expect(greetingFor(DateTime(2026, 10, 3, 18, 59)), 'Buenas tardes');
    expect(greetingFor(DateTime(2026, 10, 3, 19)), 'Buenas noches');
    expect(greetingFor(DateTime(2026, 10, 3, 4, 59)), 'Buenas noches');
  });

  test('AC2: fecha y hora en es-CO', () {
    expect(longDateEs(DateTime(2026, 10, 3)), 'sábado 3 de octubre');
    expect(longDateEs(DateTime(2026, 9, 28)), 'lunes 28 de septiembre');
    expect(timeEs(DateTime(2026, 10, 3, 8, 5)), '8:05');
  });
}
