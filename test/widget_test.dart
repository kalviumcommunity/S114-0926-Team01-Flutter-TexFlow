import 'package:flutter_test/flutter_test.dart';
import 'package:texflow/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const TexFlowApp());
    expect(find.text('TexFlow'), findsOneWidget);
  });
}
