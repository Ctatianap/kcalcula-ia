import 'package:calorias_ia/features/goals/profile_controller.dart';
import 'package:calorias_ia/features/goals/profile_screen.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hoy fijo para los tests de controlador.
final _today = DateTime(2026, 10, 8);

ProfileController _controller() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProfileController(storage: StorageRepository(db), now: () => _today);
}

Future<AppDatabase> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Elige [text] en el selector [key].
Future<void> _select(WidgetTester tester, String key, String text) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  final menu = find.byType(Scrollable).last;
  final option = find.descendant(of: menu, matching: find.text(text));
  try {
    await tester.scrollUntilVisible(option, 100, scrollable: menu);
  } on StateError {
    await tester.scrollUntilVisible(option, -100, scrollable: menu);
  }
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  group('SPEC-041 controlador', () {
    test('AC4: febrero de 2000 tiene 29; febrero de 1999, no', () {
      final c = _controller();
      c.setBirthMonth(2);
      c.setBirthYear(2000);
      expect(c.birthDays.last, 29);
      c.setBirthYear(1999);
      expect(c.birthDays.last, 28);
    });

    test('AC5: años de (hoy − 18) a (hoy − 100), del más reciente', () {
      final years = _controller().birthYears;
      expect(years.first, 2008);
      expect(years.last, 1926);
      expect(years, hasLength(83));
    });

    test('R3: 31 de marzo → febrero deja el día sin elegir y lo pide', () {
      final c = _controller();
      c
        ..setBirthYear(1990)
        ..setBirthMonth(3)
        ..setBirthDay(31);
      expect(c.age, 36);
      c.setBirthMonth(2);
      expect(c.birthDay, isNull);
      expect(c.birthDateError, birthDateMissingMessage);
    });

    test('R3: un día que sigue existiendo no cambia', () {
      final c = _controller()
        ..setBirthYear(1990)
        ..setBirthMonth(3)
        ..setBirthDay(15)
        ..setBirthMonth(2);
      expect(c.birthDay, 15);
    });

    test(
      'Edge: un año guardado fuera de la lista se sigue mostrando',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = StorageRepository(db);
        await repo.saveUserProfile(
          sex: 'female',
          birthDate: DateTime(1920, 5, 1),
          heightCm: 160,
          weightKg: 60,
          activityLevel: 'sedentary',
        );
        final c = ProfileController(storage: repo, now: () => _today);
        await c.load();
        expect(c.birthYears, contains(1920));
        expect(c.birthDateError, ageRangeMessage);
      },
    );
  });

  testWidgets('AC1: elegir 15, marzo, 1990 muestra la edad y la guarda', (
    tester,
  ) async {
    final db = await _pump(tester);
    await tester.tap(find.text('Femenino'));
    await _select(tester, 'profile-birth-day', '15');
    await _select(tester, 'profile-birth-month', 'marzo');
    await _select(tester, 'profile-birth-year', '1990');
    final now = DateTime.now();
    final age =
        now.year -
        1990 -
        (now.month < 3 || (now.month == 3 && now.day < 15) ? 1 : 0);
    expect(find.text('$age años'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('profile-height')), '165');
    await tester.enterText(find.byKey(const Key('profile-weight')), '63');
    await tester.tap(find.text('Actividad ligera'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
    await tester.pumpAndSettle();
    final profile = await StorageRepository(db).getUserProfile();
    expect(profile!.birthDate, DateTime(1990, 3, 15));
  });

  testWidgets('AC3: 31 de marzo → febrero: pide el día y no deja guardar', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Femenino'));
    await _select(tester, 'profile-birth-year', '1990');
    await _select(tester, 'profile-birth-month', 'marzo');
    await _select(tester, 'profile-birth-day', '31');
    await tester.enterText(find.byKey(const Key('profile-height')), '165');
    await tester.enterText(find.byKey(const Key('profile-weight')), '63');
    await tester.tap(find.text('Actividad ligera'));
    await tester.pump();
    final save = find.widgetWithText(FilledButton, 'Guardar perfil');
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await _select(tester, 'profile-birth-month', 'febrero');
    expect(find.text(birthDateMissingMessage), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets(
    'AC5 + AC6: sin campo de texto para la fecha; años desde hoy − 18',
    (tester) async {
      await _pump(tester);
      for (final label in ['Día', 'Mes', 'Año']) {
        expect(find.widgetWithText(InputDecorator, label), findsOneWidget);
      }
      expect(
        find.widgetWithText(TextField, 'Fecha de nacimiento'),
        findsNothing,
      );
      expect(
        find.widgetWithText(TextField, 'Fecha de nacimiento (dd/mm/aaaa)'),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('profile-birth-year')));
      await tester.pumpAndSettle();
      final year = DateTime.now().year;
      final menu = find.byType(Scrollable).last;
      expect(
        find.descendant(of: menu, matching: find.text('${year - 18}')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: menu, matching: find.text('${year - 17}')),
        findsNothing,
      );
    },
  );

  testWidgets('texto grande (×2) en 360 px: los selectores no desbordan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _select(tester, 'profile-birth-month', 'septiembre');
    expect(tester.takeException(), isNull);
  });
}
