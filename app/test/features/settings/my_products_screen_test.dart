import 'package:calorias_ia/features/review/personal_product_picker_screen.dart';
import 'package:calorias_ia/features/settings/my_products_screen.dart';
import 'package:calorias_ia/infra/catalog/catalog_providers.dart';
import 'package:calorias_ia/infra/storage/app_database.dart';
import 'package:calorias_ia/infra/storage/storage_providers.dart';
import 'package:calorias_ia/infra/storage/storage_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixture_catalog.dart';

Future<({AppDatabase db, int id})> _pump(
  WidgetTester tester, {
  Widget home = const MyProductsScreen(),
  bool withProduct = true,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  var id = -1;
  if (withProduct) {
    id = (await tester.runAsync(
      () => StorageRepository(db).savePersonalProduct(
        nameEs: 'Pan',
        energyKcal100: 70 * 100 / 27,
        proteinG100: 2.8 * 100 / 27,
        carbsG100: 15 * 100 / 27,
        fatG100: 0.2 * 100 / 27,
        servingGrams: 27,
        sourceRef: 'test',
      ),
    ))!;
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        catalogRepositoryProvider.overrideWithValue(buildFixtureCatalog()),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return (db: db, id: id);
}

Future<void> _openEdit(WidgetTester tester, int id) async {
  await tester.tap(find.byKey(Key('my-product-$id')));
  await tester.pumpAndSettle();
  expect(find.text('Editar producto'), findsOneWidget);
}

Future<void> _tapButton(WidgetTester tester, Finder button) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('R1: lista con porción y kcal por porción', (tester) async {
    await _pump(tester);
    expect(find.text('Pan'), findsOneWidget);
    expect(find.text('1 porción = 27,0 g · 70 kcal'), findsOneWidget);
  });

  testWidgets('R1: sin productos, el mensaje', (tester) async {
    await _pump(tester, withProduct: false);
    expect(find.text(noProductsMessage), findsOneWidget);
  });

  testWidgets(
    'AC1: renombrar "Pan" → "Pan tajado integral" se ve en la lista y en "Elegir de mis productos"',
    (tester) async {
      final pumped = await _pump(tester);
      await _openEdit(tester, pumped.id);
      await tester.enterText(
        find.byKey(const Key('edit-product-name')),
        'Pan tajado integral',
      );
      await _tapButton(
        tester,
        find.widgetWithText(FilledButton, 'Guardar cambios'),
      );
      expect(find.text('Mis productos'), findsOneWidget);
      expect(find.text('Pan tajado integral'), findsOneWidget);
    },
  );

  testWidgets('AC1: "Elegir de mis productos" muestra el nombre nuevo', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() async {
      final repo = StorageRepository(db);
      final id = await repo.savePersonalProduct(
        nameEs: 'Pan',
        energyKcal100: 260,
        proteinG100: 9,
        carbsG100: 48,
        fatG100: 3,
        servingGrams: 27,
        sourceRef: 'test',
      );
      await repo.updatePersonalProduct(
        id: id,
        nameEs: 'Pan tajado integral',
        servingUnit: 'g',
        aliases: const [],
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: PersonalProductPickerScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pan tajado integral'), findsOneWidget);
  });

  testWidgets('R2: agregar el alias "mi pan" y la unidad ml se guardan', (
    tester,
  ) async {
    final pumped = await _pump(tester);
    await _openEdit(tester, pumped.id);
    await tester.enterText(
      find.byKey(const Key('edit-product-new-alias')),
      'mi pan',
    );
    await tester.tap(find.byKey(const Key('edit-product-add-alias')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('alias-mi pan')), findsOneWidget);
    await tester.tap(find.text('ml'));
    await tester.pumpAndSettle();
    await _tapButton(
      tester,
      find.widgetWithText(FilledButton, 'Guardar cambios'),
    );

    final repo = StorageRepository(pumped.db);
    final aliases = await tester.runAsync(repo.getPersonalProductAliases);
    expect(aliases, {
      pumped.id: ['mi pan'],
    });
    final product = await tester.runAsync(
      () => repo.getPersonalProductById(pumped.id),
    );
    expect(product!.servingUnit, 'ml');
    expect(find.textContaining('También: mi pan'), findsOneWidget);
  });

  testWidgets(
    'caso borde: un alias igual a un alimento del catálogo avisa que gana el producto',
    (tester) async {
      final pumped = await _pump(tester);
      await _openEdit(tester, pumped.id);
      await tester.enterText(
        find.byKey(const Key('edit-product-new-alias')),
        'arepa',
      );
      await tester.tap(find.byKey(const Key('edit-product-add-alias')));
      await tester.pumpAndSettle();
      expect(
        find.text('Cuando digas «arepa» usaremos este producto.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('AC6: borrar con confirmación lo quita de la lista', (
    tester,
  ) async {
    final pumped = await _pump(tester);
    await _openEdit(tester, pumped.id);
    await _tapButton(tester, find.byKey(const Key('edit-product-delete')));
    expect(find.text('¿Borrar «Pan»?'), findsOneWidget);
    expect(
      find.text('Las comidas que ya registraste no cambian.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await tester.pumpAndSettle();
    expect(find.text(noProductsMessage), findsOneWidget);
  });

  testWidgets('AC6: "Cancelar" no borra', (tester) async {
    final pumped = await _pump(tester);
    await _openEdit(tester, pumped.id);
    await _tapButton(tester, find.byKey(const Key('edit-product-delete')));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar producto'), findsOneWidget);
  });

  testWidgets('AC9: nombre vacío no se guarda', (tester) async {
    final pumped = await _pump(tester);
    await _openEdit(tester, pumped.id);
    await tester.enterText(find.byKey(const Key('edit-product-name')), '  ');
    await _tapButton(
      tester,
      find.widgetWithText(FilledButton, 'Guardar cambios'),
    );
    expect(find.text(productNameRequiredMessage), findsOneWidget);
    expect(find.text('Editar producto'), findsOneWidget);
  });

  test('AC9: alias vacío, repetido o número 11', () {
    expect(
      validateNewAlias(' ', current: const [], productName: 'Pan'),
      aliasRequiredMessage,
    );
    expect(
      validateNewAlias('Mi Pán', current: const ['mi pan'], productName: 'Pan'),
      aliasRepeatedMessage,
    );
    expect(
      validateNewAlias('pan', current: const [], productName: 'Pan'),
      aliasRepeatedMessage,
    );
    expect(
      validateNewAlias(
        'otro',
        current: [for (var i = 0; i < 10; i++) 'alias $i'],
        productName: 'Pan',
      ),
      tooManyAliasesMessage,
    );
    expect(
      validateNewAlias('mi pan', current: const [], productName: 'Pan'),
      isNull,
    );
  });

  testWidgets('AC9: alias repetido muestra el mensaje y no se agrega', (
    tester,
  ) async {
    final pumped = await _pump(tester);
    await _openEdit(tester, pumped.id);
    await tester.enterText(
      find.byKey(const Key('edit-product-new-alias')),
      'PAN',
    );
    await tester.tap(find.byKey(const Key('edit-product-add-alias')));
    await tester.pumpAndSettle();
    expect(find.text(aliasRepeatedMessage), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
  });
}
