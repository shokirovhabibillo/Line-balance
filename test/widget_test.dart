import 'package:flutter_test/flutter_test.dart';

import 'package:line_balance_platform/app/app.dart';

void main() {
  testWidgets('foundation home page renders', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());

    expect(find.text('Line Balance Platform'), findsOneWidget);
    expect(find.text('Time Study'), findsOneWidget);
    expect(find.text('Line Balance'), findsOneWidget);
    expect(find.text('VSM'), findsOneWidget);
    expect(find.text('Downtime'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('Time Study opens from home', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());

    await tester.tap(find.text('Time Study'));
    await tester.pumpAndSettle();

    expect(find.text('Xronometraj sessiyasi'), findsOneWidget);
    expect(find.text('Siklik'), findsOneWidget);
    expect(find.text('Nosiklik'), findsOneWidget);
    expect(find.text('Ish elementlari (0)'), findsOneWidget);
  });
}
