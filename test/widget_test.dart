import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/app/app.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_study_page.dart';

void main() {
  Future<void> openTimeStudy(WidgetTester tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    await tester.tap(find.text('Time Study'));

    // The Material route transition needs frames before TimeStudyPage is
    // mounted. Do not wait for all animations because TimeStudyPage also has
    // an indeterminate loading spinner while saved data is loaded.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(TimeStudyPage).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byType(TimeStudyPage), findsOneWidget);

    // Once the page is mounted, wait for its real loading operation to finish.
    // This avoids both arbitrary timing and pumpAndSettle() hanging on the
    // indeterminate CircularProgressIndicator.
    for (var i = 0; i < 40; i++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  Future<void> scrollToCycleRecords(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const Key('cycle_records_header')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home page renders', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());

    expect(find.text('Line Balance Platform'), findsOneWidget);
    expect(find.text('Time Study'), findsOneWidget);
  });

  testWidgets('Time Study page opens', (tester) async {
    await openTimeStudy(tester);

    // Check content at the top before scrolling.
    expect(find.text('Xronometraj sessiyasi'), findsOneWidget);

    // The cycle section is below the fold, so scroll to it before checking.
    await scrollToCycleRecords(tester);

    expect(find.byKey(const Key('cycle_records_header')), findsOneWidget);
    expect(find.text('Cycle yozuvlari (0)'), findsOneWidget);
  });

  testWidgets('Time Study records one cycle without elements', (tester) async {
    await openTimeStudy(tester);

    await tester.tap(find.text('Start cycle'));
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });

    await tester.tap(find.text('Finish cycle'));
    await tester.pump();

    await scrollToCycleRecords(tester);

    expect(find.text('Cycle yozuvlari (1)'), findsOneWidget);
  });

  testWidgets('work element dialog shows requirement and verification options',
      (tester) async {
    await openTimeStudy(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('work_elements_header')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Qo‘shish'));
    await tester.pumpAndSettle();

    expect(find.text('Ish elementi qo‘shish'), findsOneWidget);
    expect(find.text('Xavfsizlik'), findsOneWidget);
    expect(find.text('Sifat'), findsOneWidget);
    expect(find.text('Ketma-ketlik'), findsOneWidget);
    expect(find.text('Qadam ichidagi ketma-ketlik'), findsOneWidget);
    expect(find.text('QCOS'), findsOneWidget);
    expect(find.text('Hech narsa'), findsOneWidget);
    expect(find.text('Ko‘rish'), findsOneWidget);
    expect(find.text('Eshitish'), findsOneWidget);
    expect(find.text('Teginish'), findsOneWidget);
    expect(find.text('O‘lchash'), findsOneWidget);
    expect(find.text('Asos / standart / hujjat'), findsOneWidget);
  });
}
