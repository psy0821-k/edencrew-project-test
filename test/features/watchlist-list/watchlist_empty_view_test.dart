import 'package:edencrew_assignment_starter/features/watchlist-list/watchlist_empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchlistEmptyView', () {
    testWidgets(
      'should render the ico_star icon, title and caption unchanged from before the refactor',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: WatchlistEmptyView()),
        );

        final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
        expect(
          (svg.bytesLoader as SvgAssetLoader).assetName,
          'assets/icons/ico_star.svg',
        );
        expect(find.text('관심 종목이 없습니다'), findsOneWidget);
        expect(
          find.text('검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.'),
          findsOneWidget,
        );
      },
    );
  });
}
