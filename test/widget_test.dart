import 'package:flutter_test/flutter_test.dart';

import 'package:backoffice_officine/main.dart';

void main() {
  testWidgets('Démarrage : écran de sélection du profil', (WidgetTester tester) async {
    await tester.pumpWidget(const PharmacieDemoApp());

    expect(find.text('Pharmacie Démo'), findsOneWidget);
    expect(find.text('Titulaire (démo)'), findsOneWidget);
    expect(find.text('Préparateur (démo)'), findsOneWidget);
    expect(find.text('Stagiaire (démo)'), findsOneWidget);
  });
}
