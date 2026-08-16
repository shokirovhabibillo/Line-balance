import 'package:flutter_test/flutter_test.dart';

import 'package:line_balance_platform/app/app.dart';

void main() {
  testWidgets('home page renders', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());

    expect(find.text('Line Balance Platform'), findsOneWidget);
    expect(find.text('Time Study'), findsOneWidget);
  });

  testWidgets('Time Study records one cycle', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());

    await tester.tap(find.text('Time Study'));
    await tester.pumpAndSettle();

    expect(find.text('Cycle yozuvlari (0)'), findsOneWidget);

    await tester.tap(find.text('Start cycle'));

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    await tester.tap(find.text('Finish cycle'));
    await tester.pump();

    expect(find.text('Cycle yozuvlari (1)'), findsOneWidget);
  });
}
