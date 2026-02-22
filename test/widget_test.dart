import 'package:flutter_test/flutter_test.dart';
import 'package:ifridge_app/main.dart';

void main() {
  testWidgets('App renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const IFridgeApp());

    // Verify bottom nav items exist
    expect(find.text('Shelf'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
