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
  testWidgets('History opens', (tester) async => open(tester, 'History', HistoryPage));
}
