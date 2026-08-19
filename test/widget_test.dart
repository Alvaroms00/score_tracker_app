// Basic Flutter widget tests for the score tracker app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:contador_de_puntuaciones/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Main menu navigates to the generic counter screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScoreTrackerApp());

    // The app opens on the main menu.
    expect(find.text('Contador general'), findsOneWidget);

    // Tapping the button navigates to the generic counter screen.
    await tester.tap(find.text('Contador general'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Contador general'), findsOneWidget);
    expect(find.text('Añadir jugador'), findsOneWidget);
  });

  testWidgets('Generic counter screen adds a player and increments their score',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ScoreTrackerApp());
    await tester.tap(find.text('Contador general'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Introduce el nombre del jugador'),
        'Ana');
    await tester.tap(find.text('Añadir jugador'));
    await tester.pump();

    expect(find.text('Ana: 0 puntos'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Puntos'), '5');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Ana: 5 puntos'), findsOneWidget);
  });
}
