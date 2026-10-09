import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/app/app.dart';
import 'package:line_balance_platform/features/catalog/presentation/catalog_page.dart';
import 'package:line_balance_platform/features/downtime/presentation/downtime_page.dart';
import 'package:line_balance_platform/features/history/presentation/history_page.dart';
import 'package:line_balance_platform/features/line_balance/presentation/line_balance_page.dart';
import 'package:line_balance_platform/features/vsm/presentation/vsm_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> open(WidgetTester tester, String title, Type pageType) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LineBalanceApp());
    final keyName = title.toLowerCase().replaceAll(' ', '_');
    final card = find.byKey(Key('module_card_$keyName'));
    expect(card, findsOneWidget);
    await tester.scrollUntilVisible(
      card,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(card, findsOneWidget);
    await tester.tap(card, warnIfMissed: true);
    await tester.pump();
    for (var i = 0; i < 20 && find.byType(pageType).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byType(pageType), findsOneWidget);
  }

  testWidgets('Catalog opens', (tester) async => open(tester, 'Catalog', CatalogPage));
  testWidgets('Line Balance opens', (tester) async => open(tester, 'Line Balance', LineBalancePage));
  testWidgets('VSM opens', (tester) async => open(tester, 'VSM', VsmPage));
  testWidgets('Downtime opens', (tester) async => open(tester, 'Downtime', DowntimePage));
  testWidgets('History opens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LineBalanceApp());
    final scrollView = find.byType(CustomScrollView);
    expect(scrollView, findsOneWidget);
    final historyKey = const Key('module_card_history');
    for (var i = 0; i < 12 && find.byKey(historyKey).evaluate().isEmpty; i++) {
      await tester.drag(scrollView, const Offset(0, -500));
      await tester.pump();
    }
    final card = find.byKey(historyKey);
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pump();
    final inkWell = find.descendant(of: card, matching: find.byType(InkWell));
    expect(inkWell, findsOneWidget);
    tester.widget<InkWell>(inkWell).onTap!();
    await tester.pump();
    for (var i = 0; i < 20 && find.byType(HistoryPage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.byType(HistoryPage), findsOneWidget);
  });

  testWidgets('4M / People opens', (tester) async {
    await tester.pumpWidget(const LineBalanceApp());
    final card = find.byKey(const Key('module_card_4m_/_people'));
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    final inkWell = find.descendant(of: card, matching: find.byType(InkWell));
    tester.widget<InkWell>(inkWell).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('4M Foundation'), findsOneWidget);
    expect(find.text('Man'), findsOneWidget);
    expect(find.text('Machine'), findsOneWidget);
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Method'), findsOneWidget);
  });

}
