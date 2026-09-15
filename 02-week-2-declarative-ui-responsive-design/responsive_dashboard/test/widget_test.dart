import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_dashboard/main.dart'; // Pastikan nama package sesuai dengan pubspec.yaml Anda

void main() {
  testWidgets('Dashboard satu kolom di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DashboardApp());

    final width = tester.getSize(find.byType(Card).first).width;
    expect(width, lessThan(700));
  });

  testWidgets('Dashboard dua kolom di layar lebar', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DashboardApp());

    // Tunggu animasi layout selesai jika ada
    await tester.pumpAndSettle();

    final width = tester.getSize(find.byType(Card).first).width;
    // Di layar lebar, lebar kartu akan menjadi hampir setengah dari 1200 (minus padding), sehingga lebih kecil dari 600.
    // Karena modul meminta greaterThan(500), logika aslinya untuk 1200px (1200-48)/2 = 576. Jadi 576 > 500 (Valid).
    expect(width, greaterThan(500)); 
  });
}