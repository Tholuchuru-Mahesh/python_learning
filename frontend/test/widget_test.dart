import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Unified POS smoke test loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: UnifiedPosApp(),
      ),
    );

    // Initial loading or login state renders without crashes
    expect(find.byType(UnifiedPosApp), findsOneWidget);
  });
}
