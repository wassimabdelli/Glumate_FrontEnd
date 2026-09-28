import 'package:flutter_test/flutter_test.dart';
import 'package:glumate_mobile/navigation/glumate_root.dart';

void main() {
  testWidgets('shows GluMate login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GluMateApp());

    expect(find.text('GluMate'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
  });
}
