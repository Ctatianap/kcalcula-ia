import 'package:calorias_ia/ui/components/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AC4: la fracción se limita entre 0 y 1', () {
    expect(const ProgressRing(fraction: -0.2).clampedFraction, 0);
    expect(const ProgressRing(fraction: 0).clampedFraction, 0);
    expect(const ProgressRing(fraction: 0.5).clampedFraction, 0.5);
    expect(const ProgressRing(fraction: 1).clampedFraction, 1);
    expect(const ProgressRing(fraction: 1.7).clampedFraction, 1);
    expect(const ProgressRing(fraction: double.nan).clampedFraction, 0);
  });

  testWidgets('AC4: dibuja el anillo y muestra el contenido central', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressRing(
            fraction: 0.5,
            size: 84,
            center: Text('893'),
            semanticsLabel: '893 de 2.000 kcal',
          ),
        ),
      ),
    );
    expect(find.text('893'), findsOneWidget);
    expect(find.bySemanticsLabel('893 de 2.000 kcal'), findsOneWidget);
    expect(tester.getSize(find.byType(ProgressRing)), const Size(84, 84));
  });
}
