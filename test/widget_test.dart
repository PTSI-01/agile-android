import 'package:agile/main.dart';
import 'package:agile/screens/supplier/supplier_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login validates input, toggles password and interaction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.text('AGILE JAYA ABADI'), findsOneWidget);
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Email tidak boleh kosong.'), findsOneWidget);
    expect(find.text('Password tidak boleh kosong.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'invalid');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Format email tidak valid.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'tester@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'test-only');
    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await tester.ensureVisible(find.text('Ingat saya'));
    await tester.tap(find.text('Ingat saya'));
    await tester.pump();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login supports dark mode and keyboard on small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Aktifkan mode gelap'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Aktifkan mode terang'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('SupplierListPage renders search, stats and action buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SupplierListPage(),
      ),
    );

    expect(find.text('Master Data Supplier'), findsOneWidget);
    expect(find.text('Total Pemasok'), findsOneWidget);
    expect(find.text('Tambah Supplier'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
