import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:discoverjakarta/auth/auth_notifier.dart';
import 'package:discoverjakarta/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home shows Discover Jakarta title', (WidgetTester tester) async {
    final auth = AuthNotifier();
    await auth.load();
    await tester.pumpWidget(MyApp(auth: auth));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Discover Jakarta'), findsOneWidget);
  });
}
