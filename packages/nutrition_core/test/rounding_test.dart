import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentKcal', () {
    test('redondea .5 hacia arriba (half-up)', () {
      expect(presentKcal(247.5), 248);
      expect(presentKcal(0.5), 1);
    });

    test('valores sin parte decimal .5 redondean al entero más cercano', () {
      expect(presentKcal(247.4), 247);
      expect(presentKcal(247.6), 248);
    });
  });

  group('presentMacro', () {
    test('redondea a 1 decimal, half-up', () {
      expect(presentMacro(1.25), 1.3);
      expect(presentMacro(3.14), 3.1);
    });
  });
}
