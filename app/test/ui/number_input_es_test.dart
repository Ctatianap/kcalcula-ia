import 'package:calorias_ia/ui/number_input_es.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-030 parseDecimalUpTo (2 decimales)', () {
    double? parse(String text) => parseDecimalUpTo(text, maxDecimals: 2);

    test('AC3: coma o punto, hasta 2 decimales', () {
      expect(parse('1,4'), 1.4);
      expect(parse('1.4'), 1.4);
      expect(parse('1,2'), 1.2);
      expect(parse('0,25'), 0.25);
      expect(parse('0'), 0);
      expect(parse(' 14360 '), 14360);
    });

    test('AC3: separador de miles, 3 decimales, signos o texto → null', () {
      for (final text in [
        '1.200',
        '1,234',
        '1,',
        ',5',
        '-1',
        'abc',
        '',
        '1.2.3',
      ]) {
        expect(parse(text), isNull, reason: text);
      }
    });

    test('parseDecimal sigue aceptando solo un decimal', () {
      expect(parseDecimal('63,5'), 63.5);
      expect(parseDecimal('63,55'), isNull);
    });
  });

  group('SPEC-030 formatDecimalEs', () {
    test('R2: coma, sin ceros de más, máximo 2 decimales', () {
      expect(formatDecimalEs(15.0), '15');
      expect(formatDecimalEs(2.9), '2,9');
      expect(formatDecimalEs(1.7799999999999998), '1,78');
      expect(formatDecimalEs(17.799999999999997), '17,8');
      expect(formatDecimalEs(14360), '14360');
      expect(formatDecimalEs(10), '10');
      expect(formatDecimalEs(0.25), '0,25');
    });
  });
}
