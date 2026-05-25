import 'package:flutter_test/flutter_test.dart';

import 'package:chowchow_flutter/main.dart';

void main() {
  testWidgets('App launches and shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const PetFoodApp());

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
