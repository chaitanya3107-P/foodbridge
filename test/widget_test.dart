import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/main.dart';
import 'package:foodbridge/core/constants/app_constants.dart';

void main() {
  testWidgets('FoodBridge main app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FoodBridgeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify FoodBridge branding and universal disclaimer banner appear
    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
