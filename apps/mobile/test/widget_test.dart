import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thcp_mobile/app.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ThcpApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trusted Home Connect'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
  });
}
