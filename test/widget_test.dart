import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_balance_platform/app/app.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_check_page.dart';
import 'package:line_balance_platform/features/time_study/presentation/time_study_page.dart';

void main() {
  // TimeStudyStorage uses SharedPreferences. In widget tests we provide the
  // in-memory test implementation so its async load completes deterministically.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});

  Future<void> openTimeStudy(WidgetTester tester) async {
    await tester.pumpWidget(const LineBalanceApp());

    final card = find.byKey(const Key('module_card_time_study'));
    expect(card, findsOneWidget);

    final inkWell = find.descendant(
      of: card,
      matching: find.byType(InkWell),
    );
    expect(inkWell, findsOneWidget);
    tester.widget<InkWell>(inkWell).onTap!();
    await tester.pump();

    for (var i = 0; i < 100 && find.byType(TimeStudyPage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(TimeStudyPage), findsOneWidget);

    for (var i = 0; i < 100 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
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

    expect(find.byKey(const Key('work_elements_header')), findsOneWidget);
    expect(find.byKey(const Key('time_study_menu')), findsOneWidget);
    expect(find.byKey(const Key('add_work_element')), findsOneWidget);
    expect(find.byKey(const Key('time_check_button')), findsOneWidget);

    final menu = tester.widget<PopupMenuButton<String>>(
      find.byKey(const Key('time_study_menu')),
    );
    final entries = menu.itemBuilder(tester.element(find.byKey(const Key('time_study_menu'))));
    expect(entries.whereType<PopupMenuItem<String>>().length, 3);
    expect(entries.any((e) => e.key == const Key('excel_import_item')), isTrue);
    expect(entries.any((e) => e.key == const Key('excel_export_item')), isTrue);
    expect(entries.any((e) => e.key == const Key('excel_template_item')), isTrue);
  });

  testWidgets('work element dialog shows property and measurement options', (tester) async {
    await openTimeStudy(tester);

    final addButton = tester.widget<FilledButton>(
      find.byKey(const Key('add_work_element')),
    );
    expect(addButton.onPressed, isNotNull);
    addButton.onPressed!();
    await tester.pump();

    expect(find.byKey(const Key('work_element_dialog_title')), findsOneWidget);
    expect(find.byKey(const Key('work_element_name')), findsOneWidget);
    expect(find.text('Xususiyati'), findsOneWidget);
    expect(find.text('Start + Finish Element'), findsOneWidget);
    expect(find.text('Cycle-linked / Finish-only'), findsOneWidget);
    expect(find.text('Xavfsizlik'), findsOneWidget);
    expect(find.text('O‘lchash'), findsOneWidget);
  });

  testWidgets('Time Check opens after an element is created', (tester) async {
    await openTimeStudy(tester);

    final addButton = tester.widget<FilledButton>(
      find.byKey(const Key('add_work_element')),
    );
    expect(addButton.onPressed, isNotNull);
    addButton.onPressed!();
    await tester.pump();

    final nameField = find.byKey(const Key('work_element_name'));
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Detalni olish');

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('work_element_dialog_save')),
    );
    expect(saveButton.onPressed, isNotNull);
    saveButton.onPressed!();
    await tester.pump();

    for (var i = 0; i < 30; i++) {
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('time_check_button')),
      );
      if (button.onPressed != null) break;
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Detalni olish'), findsOneWidget);
    final timeCheckButton = tester.widget<FilledButton>(
      find.byKey(const Key('time_check_button')),
    );
    expect(timeCheckButton.onPressed, isNotNull);
    timeCheckButton.onPressed!();
    await tester.pump();

    for (var i = 0; i < 40 && find.byType(TimeCheckPage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(TimeCheckPage), findsOneWidget);
    expect(find.text('START CYCLE'), findsOneWidget);
    expect(find.text('START ELEMENT'), findsOneWidget);
    expect(find.text('FINISH ELEMENT'), findsOneWidget);
  });
}
