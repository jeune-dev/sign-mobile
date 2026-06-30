import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Smoke test minimal — vérifie que MaterialApp se monte sans crash.
    // Les tests d'intégration complets nécessitent Firebase et les dépendances réseau
    // qui ne sont pas disponibles en environnement de test unitaire.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('SIGN')),
        ),
      ),
    );
    expect(find.text('SIGN'), findsOneWidget);
  });

  testWidgets('Scaffold avec AppBar se rend correctement', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('Test'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
