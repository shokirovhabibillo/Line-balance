import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/app/app.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_study_page.dart';

void main() {
  testWidgets('home page renders', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    expect(find.text('Line Balance Platform'), findsOneWidget);
    expect(find.text('Time Study'), findsOneWidget);
  });

  testWidgets('Time Study page opens', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    await tester.tap(find.text('Time Study'));
    await tester.pumpAndSettle();

    expect(find.byType(TimeStudyPage), findsOneWidget);
    expect(find.text('Xronometraj sessiyasi'), findsOneWidget);
    expect(find.textContaining('Cycle yozuvlari (0)'), findsOneWidget);
  });

  testWidgets('Time Study records one cycle', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    await tester.tap(find.text('Time Study'));
    await tester.pumpAndSettle();

    expect(find.byType(TimeStudyPage), findsOneWidget);
    expect(find.textContaining('Cycle yozuvlari (0)'), findsOneWidget);

    await tester.tap(find.text('Start cycle'));
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });

    await tester.tap(find.text('Finish cycle'));
    await tester.pump();

    expect(find.textContaining('Cycle yozuvlari (1)'), findsOneWidget);
  });
}
