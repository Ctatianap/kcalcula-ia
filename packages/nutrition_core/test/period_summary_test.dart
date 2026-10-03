import 'package:nutrition_core/nutrition_core.dart';
import 'package:test/test.dart';

LoggedDay _day(
  DateTime date,
  double kcal, {
  double p = 0,
  double c = 0,
  double f = 0,
}) => (date: date, totals: (energyKcal: kcal, proteinG: p, carbsG: c, fatG: f));

void main() {
  group('AC1: promedio diario solo sobre días con registros', () {
    test('1.500 y 1.700 (y un día sin comidas) → 1.600 sobre 2 días', () {
      // El día sin comidas no llega a la lista: no es un día en 0.
      final days = [
        _day(DateTime(2026, 9, 28), 1500, p: 80, c: 150, f: 50),
        _day(DateTime(2026, 9, 30), 1700, p: 100, c: 201, f: 61.5),
      ];
      final summary = summarizePeriod(days);
      expect(summary.loggedDays, 2);
      expect(summary.average!.energyKcal, 1600);
      expect(summary.average!.proteinG, 90);
      expect(summary.average!.carbsG, closeTo(175.5, 1e-9));
      expect(summary.average!.fatG, closeTo(55.75, 1e-9));
      // Se redondea solo al presentar.
      expect(formatMacroEs(summary.average!.fatG), '55,8');
    });

    test('sin días con registros → sin promedio', () {
      final summary = summarizePeriod(const []);
      expect(summary.loggedDays, 0);
      expect(summary.average, isNull);
    });

    test('suma sin redondear antes de dividir', () {
      final avg = dailyAverage([
        _day(DateTime(2026, 9, 1), 100.4),
        _day(DateTime(2026, 9, 2), 100.4),
        _day(DateTime(2026, 9, 3), 100.4),
      ])!;
      expect(avg.energyKcal, closeTo(100.4, 1e-9));
      expect(presentKcal(avg.energyKcal), 100);
    });
  });

  group('AC2: días en meta', () {
    test('meta 2.000 con 1.900, 2.300 y 1.500 → 1 de 3', () {
      final days = [
        _day(DateTime(2026, 9, 28), 1900),
        _day(DateTime(2026, 9, 29), 2300),
        _day(DateTime(2026, 9, 30), 1500),
      ];
      final summary = summarizePeriod(days, goalKcal: 2000);
      expect(summary.daysOnGoal, 1);
      expect(summary.loggedDays, 3);
    });

    test('los límites de SPEC-011 cuentan como en la meta (1.800 y 2.200)', () {
      final days = [
        _day(DateTime(2026, 9, 28), 1800),
        _day(DateTime(2026, 9, 29), 2200),
      ];
      expect(daysOnGoal(days, goalKcal: 2000), 2);
    });

    test('sin meta → null (R7)', () {
      expect(daysOnGoal([_day(DateTime(2026, 9, 28), 1900)]), isNull);
      expect(
        daysOnGoal([_day(DateTime(2026, 9, 28), 1900)], goalKcal: 0),
        isNull,
      );
    });
  });

  group('AC4: promedios por semana (lunes a domingo)', () {
    test('mes del 4 sep al 3 oct 2026: semanas desde el lunes 31 ago', () {
      final days = [
        _day(DateTime(2026, 9, 4), 1000), // vie, semana del 31 ago
        _day(DateTime(2026, 9, 6), 2000), // dom, misma semana
        _day(DateTime(2026, 9, 7), 1800), // lun, semana del 7 sep
        _day(DateTime(2026, 10, 3), 1500), // sáb, semana del 28 sep
        _day(DateTime(2026, 9, 1), 9999), // fuera del periodo: no cuenta
      ];
      final weeks = weeklyAverages(
        days,
        from: DateTime(2026, 9, 4),
        to: DateTime(2026, 10, 3),
      );
      expect(weeks.map((w) => w.monday), [
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 7),
        DateTime(2026, 9, 14),
        DateTime(2026, 9, 21),
        DateTime(2026, 9, 28),
      ]);
      expect(weeks[0].averageKcal, 1500);
      expect(weeks[0].loggedDays, 2);
      expect(weeks[1].averageKcal, 1800);
      expect(weeks[2].averageKcal, isNull);
      expect(weeks[2].loggedDays, 0);
      expect(weeks[4].averageKcal, 1500);
    });

    test('mondayOf usa la fecha de calendario (domingo → lunes anterior)', () {
      expect(mondayOf(DateTime(2026, 10, 4, 23)), DateTime(2026, 9, 28));
      expect(mondayOf(DateTime(2026, 9, 28)), DateTime(2026, 9, 28));
      expect(mondayOf(DateTime(2026, 3, 1)), DateTime(2026, 2, 23));
    });
  });
}
