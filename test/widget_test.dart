import 'package:flutter_test/flutter_test.dart';

import 'package:password_strength_car_controller/main.dart';

void main() {
  testWidgets('renders the car controller title', (WidgetTester tester) async {
    await tester.pumpWidget(const PasswordStrengthCarApp());
    await tester.pump();

    expect(find.text('Password Strength Car Controller'), findsOneWidget);
  });
}
