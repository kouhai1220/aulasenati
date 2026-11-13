import 'package:flutter_test/flutter_test.dart';
import 'package:aulasenati/main.dart';

void main() {
  testWidgets('La aplicación inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const AulaPuntosApp());

    expect(find.text('Panel del Instructor'), findsOneWidget);
    expect(find.text('Mis Grupos'), findsWidgets);
  });
}