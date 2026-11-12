import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_lobao/main.dart';

void main() {
  testWidgets('App starts with splash screen displaying title and slogan', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: TimeLobaoApp(),
      ),
    );

    // Verify that the title "TIME LOBÃO" is shown.
    expect(find.text('TIME LOBÃO'), findsOneWidget);

    // Verify that the slogan is shown.
    expect(find.text('QUEM ACORDA CEDO BEBE ÁGUA LIMPA'), findsOneWidget);

    // Pump to let the navigation delayed timer fire and finish.
    await tester.pumpAndSettle();
  });
}
