import 'package:flutter_test/flutter_test.dart';
import 'package:texflow/app.dart';

void main() {
  testWidgets('Homepage renders key TexFlow marketing content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TexFlowApp());

    expect(find.text('TexFlow'), findsOneWidget);
    expect(find.text('Smart textile production'), findsOneWidget);
    expect(find.text('Track every stage'), findsOneWidget);
  });
}
