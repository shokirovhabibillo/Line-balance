import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/app/app.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_study_page.dart';

void main() {
  testWidgets('home page renders', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    expect(find.text('Line Balance Platform'), findsOneWidget);
    expect(find.text('Time Study'), findsOneWidget);
  });

  Future<void> openTimeStudy(WidgetTester tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    await tester.tap(find.text('Time Study'));
    await tester.pumpAndSettle();
    expect(find.byType(TimeStudyPage), findsOneWidget);
  }

  Future<void> showCycleSection(WidgetTester tester) async {
    final header = find.byKey(const Key('cycle_records_header'));
    await tester.scrollUntilVisible(header, 500);
    await tester.pumpAndSettle();
  }

  testWidgets('Time Study page opens', (tester) async {
    await openTimeStudy(tester);
    expect(find.text('Time Study'), findsOneWidget);
    expect(find.text('Xronometraj sessiyasi'), findsOneWidget);

    await showCycleSection(tester);
    expect(find.byKey(const Key('cycle_records_header')), findsOneWidget);
    expect(find.text('Cycle yozuvlari (0)'), findsOneWidget);
  });

  testWidgets('Time Study records one cycle', (tester) async {
    await openTimeStudy(tester);

    await showCycleSection(tester);
    expect(find.text('Cycle yozuvlari (0)'), findsOneWidget);

    // Return to the timer controls before starting the cycle.
    await tester.scrollUntilVisible(find.text('Start cycle'), -500);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start cycle'));
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });

    await tester.tap(find.text('Finish cycle'));
    await tester.pump();

    await showCycleSection(tester);
    expect(find.byKey(const Key('cycle_records_header')), findsOneWidget);
    expect(find.text('Cycle yozuvlari (1)'), findsOneWidget);
  });
}
