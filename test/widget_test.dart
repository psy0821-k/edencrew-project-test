import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/app/app.dart';

void main() {
  testWidgets('앱이 다크 테마로 렌더링되고 관심 화면이 기본으로 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EdencrewAssignmentApp()),
    );

    expect(find.text('관심'), findsWidgets); // AppBar 타이틀 + 탭 라벨
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('하단 탭에서 검색을 누르면 검색 화면으로 전환된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EdencrewAssignmentApp()),
    );

    await tester.tap(find.text('검색').last);
    await tester.pumpAndSettle();

    expect(find.text('검색 화면 (더미) — 탭하면 상세로 이동'), findsOneWidget);
  });

  testWidgets('관심 화면의 더미 항목을 탭하면 상세 화면으로 push된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EdencrewAssignmentApp()),
    );

    await tester.tap(find.text('관심 화면 (더미) — 탭하면 상세로 이동'));
    await tester.pumpAndSettle();

    expect(find.textContaining('symbol: 005930'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('관심 화면 (더미) — 탭하면 상세로 이동'), findsOneWidget);
  });
}
