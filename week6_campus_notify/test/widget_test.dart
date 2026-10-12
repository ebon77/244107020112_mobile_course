import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/features/notes/presentation/pages/notes_page.dart';

void main() {
  testWidgets('NotesPage builds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: NotesPage()),
        ),
      ),
    );
    expect(find.byType(NotesPage), findsOneWidget);
  });
}
