import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_balance_platform/app/app.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_study_page.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_check_page.dart';

void main() {
  Future<void> prepareViewport(WidgetTester tester) async {
    // Keep Flutter's default test viewport (800x600). The production layout
    // is responsive and the widget tests should exercise the same logical
    // viewport used by the test binding.
  }

  Future<void> openTimeStudy(WidgetTester tester) async {
    await prepareViewport(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LineBalanceApp());
    await tester.tap(find.text('Time Study'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(TimeStudyPage).evaluate().isNotEmpty) break;
    }
    expect(find.byType(TimeStudyPage), findsOneWidget);
    for (var i = 0; i < 40; i++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  testWidgets('home page renders', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    expect(find.text('Line Balance Platform'), findsOneWidget);
    expect(find.text('Time Study'), findsOneWidget);
  });

  testWidgets('Time Study page opens with setup, Excel and Time Check controls', (tester) async {
    await openTimeStudy(tester);
    expect(find.text('Xronometraj sessiyasi'), findsOneWidget);
    expect(find.text('Excel import'), findsNothing); // menu is closed
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Excel import'), findsOneWidget);
    expect(find.text('Excel export'), findsOneWidget);
    expect(find.text('Excel namuna'), findsOneWidget);
  });

  testWidgets('work element dialog shows property and measurement options', (tester) async {
    await openTimeStudy(tester);
    await tester.tap(find.text('Qo‘shish'));
    await tester.pumpAndSettle();
    expect(find.text('Ish elementi qo‘shish'), findsOneWidget);
    expect(find.text('Xususiyati'), findsOneWidget);
    expect(find.text('Start + Finish Element'), findsOneWidget);
    expect(find.text('Cycle-linked / Finish-only'), findsOneWidget);
    expect(find.text('Xavfsizlik'), findsOneWidget);
    expect(find.text('O‘lchash'), findsOneWidget);
  });

  testWidgets('Time Check opens after an element is created', (tester) async {
    await openTimeStudy(tester);
    await tester.tap(find.text('Qo‘shish'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Detalni olish');
    await tester.tap(find.text('Qo‘shish').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('TIME CHECK — o‘lchashni boshlash'));
    await tester.pumpAndSettle();
    expect(find.byType(TimeCheckPage), findsOneWidget);
    expect(find.text('START CYCLE'), findsOneWidget);
    expect(find.text('START ELEMENT'), findsOneWidget);
    expect(find.text('FINISH ELEMENT'), findsOneWidget);
  });
}
