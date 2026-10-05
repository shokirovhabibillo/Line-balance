import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/app/app.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_study_page.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_check_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> openTimeStudy(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LineBalanceApp());
    await tester.tap(find.text('Time Study'));
    await tester.pump();
    for (var i = 0; i < 40 && find.byType(TimeStudyPage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(TimeStudyPage), findsOneWidget);
    for (var i = 0; i < 40 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
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
    expect(find.byKey(const Key('time_study_menu')), findsOneWidget);
    final menuFinder = find.byKey(const Key('time_study_menu'));
    final menu = tester.widget<PopupMenuButton<String>>(menuFinder);
    final entries = menu.itemBuilder(tester.element(menuFinder));
    expect(entries.whereType<PopupMenuItem<String>>().length, 3);
    final values = entries.whereType<PopupMenuItem<String>>().map((e) => e.value).toSet();
    expect(values, containsAll(<String>{'import', 'export', 'template'}));
  });

  testWidgets('work element dialog shows property and measurement options', (tester) async {
    await openTimeStudy(tester);
    final addButton = find.byKey(const Key('add_work_element'));
    expect(addButton, findsOneWidget);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work_element_dialog_title')), findsOneWidget);
    expect(find.text('Xususiyati'), findsOneWidget);
    expect(find.text('Start + Finish Element'), findsOneWidget);
    expect(find.text('Cycle-linked / Finish-only'), findsOneWidget);
    expect(find.text('Xavfsizlik'), findsOneWidget);
    expect(find.text('O‘lchash'), findsOneWidget);
  });

  testWidgets('Time Check opens after an element is created', (tester) async {
    await openTimeStudy(tester);
    final addButton = find.byKey(const Key('add_work_element'));
    expect(addButton, findsOneWidget);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('work_element_name')), 'Detalni olish');
    final saveButton = find.byKey(const Key('work_element_dialog_save'));
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    for (var i = 0; i < 20 && tester.widget<FilledButton>(find.byKey(const Key('time_check_button'))).onPressed == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Detalni olish'), findsOneWidget);
    final timeCheckButton = find.byKey(const Key('time_check_button'));
    expect(timeCheckButton, findsOneWidget);
    await tester.ensureVisible(timeCheckButton);
    await tester.tap(timeCheckButton);
    await tester.pump();
    for (var i = 0; i < 20 && find.byType(TimeCheckPage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(TimeCheckPage), findsOneWidget);
    expect(find.text('START CYCLE'), findsOneWidget);
    expect(find.text('START ELEMENT'), findsOneWidget);
    expect(find.text('FINISH ELEMENT'), findsOneWidget);
  });
}
