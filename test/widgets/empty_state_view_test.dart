import 'package:edencrew_assignment_starter/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmptyStateView', () {
    testWidgets(
      'should render the given iconAsset, title and caption as-is',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EmptyStateView(
              iconAsset: 'assets/icons/ico_star.svg',
              title: '관심 종목이 없습니다',
              caption: '캡션 문구',
            ),
          ),
        );

        expect(find.text('관심 종목이 없습니다'), findsOneWidget);
        expect(find.text('캡션 문구'), findsOneWidget);

        final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
        expect(
          (svg.bytesLoader as SvgAssetLoader).assetName,
          'assets/icons/ico_star.svg',
        );
      },
    );

    testWidgets(
      'should render arbitrary title/caption values as-is (not fixed to watchlist copy)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EmptyStateView(
              iconAsset: 'assets/icons/ico_search.svg',
              title: '종목을 검색해 보세요',
              caption: '아무 문구나 전달해도 그대로 보여야 한다',
            ),
          ),
        );

        expect(find.text('종목을 검색해 보세요'), findsOneWidget);
        expect(
          find.text('아무 문구나 전달해도 그대로 보여야 한다'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should preserve line breaks in caption when caption contains \\n',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EmptyStateView(
              iconAsset: 'assets/icons/ico_star.svg',
              title: '타이틀',
              caption: '첫째 줄\n둘째 줄',
            ),
          ),
        );

        expect(find.text('첫째 줄\n둘째 줄'), findsOneWidget);
      },
    );

    testWidgets(
      'should render without overflow when caption is very long',
      (WidgetTester tester) async {
        final longCaption = "'${'가' * 200}'와\n일치하는 검색 결과를 찾지 못했습니다.";

        await tester.pumpWidget(
          MaterialApp(
            home: EmptyStateView(
              iconAsset: 'assets/icons/ico_search_empty.svg',
              title: '검색 결과가 없습니다',
              caption: longCaption,
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final textWidget = tester.widget<Text>(find.text(longCaption));
        expect(textWidget.maxLines, 2);
        expect(textWidget.overflow, TextOverflow.ellipsis);
      },
    );
  });
}
