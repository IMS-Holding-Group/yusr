import 'package:flutter_test/flutter_test.dart';
import 'package:yusr/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const YusrApp());
    
    expect(find.text('يُسر'), findsOneWidget);
  });
}

