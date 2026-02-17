import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dark_chess/app.dart';

void main() {
  testWidgets('App launches and shows lobby', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DarkChessApp()));
    expect(find.text('暗棋'), findsOneWidget);
  });
}
