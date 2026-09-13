import 'package:edencrew_assignment_starter/entities/search/search_result.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/features/search-list/search_result_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({Set<String>? initialSymbols})
    : _symbols = initialSymbols ?? {};

  final Set<String> _symbols;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async => false;
}

Future<void> _pumpSearchResultRow(
  WidgetTester tester, {
  required SearchResult result,
  required String query,
  Set<String>? favoriteSymbols,
  void Function(String symbol)? onToggleFavorite,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(
          _FakeWatchlistRepository(initialSymbols: favoriteSymbols),
        ),
      ],
      child: MaterialApp(
        home: SearchResultRow(
          result: result,
          query: query,
          onToggleFavorite: onToggleFavorite ?? (_) {},
        ),
      ),
    ),
  );
}

const _sampleResult = SearchResult(
  symbol: '005930',
  name: '삼성전자',
  marketName: '코스피',
);

/// [span]과 그 자손 중 text가 정확히 [text]와 일치하는 TextSpan이 있는지 재귀적으로 확인한다.
/// Text.rich는 DefaultTextStyle 적용을 위해 최상위에 TextSpan을 한 겹 더 감싸므로
/// (children의 1단계만 보면 실제 하이라이트 span을 놓친다), 트리 전체를 내려가며 찾는다.
bool _containsSpanWithText(InlineSpan span, String text) {
  if (span is! TextSpan) return false;
  if (span.text == text) return true;
  return (span.children ?? []).any((child) => _containsSpanWithText(child, text));
}

void main() {
  group('SearchResultRow', () {
    testWidgets(
      'should highlight the matching range in the stock name when the name contains a range matching the query',
      (WidgetTester tester) async {
        await _pumpSearchResultRow(tester, result: _sampleResult, query: '삼성');

        final richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsWidgets);

        final matchedSpanExists = tester
            .widgetList<RichText>(richTextFinder)
            .any((widget) => _containsSpanWithText(widget.text, '삼성'));

        expect(matchedSpanExists, isTrue);
      },
    );

    testWidgets(
      'should show the "symbol · marketName" caption text',
      (WidgetTester tester) async {
        await _pumpSearchResultRow(tester, result: _sampleResult, query: '삼성');

        expect(find.textContaining('005930'), findsOneWidget);
        expect(find.textContaining('코스피'), findsOneWidget);
      },
    );

    testWidgets(
      'should show the stock name as plain text without highlight when query is an empty string',
      (WidgetTester tester) async {
        await _pumpSearchResultRow(tester, result: _sampleResult, query: '');

        expect(find.text('삼성전자'), findsOneWidget);
      },
    );

    testWidgets(
      'should truncate a very long stock name with ellipsis on a single line',
      (WidgetTester tester) async {
        const longNameResult = SearchResult(
          symbol: '005930',
          name: '아주아주아주아주아주아주아주아주아주아주긴종목이름주식회사',
          marketName: '코스피',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 200,
                  child: SearchResultRow(
                    result: longNameResult,
                    query: '',
                    onToggleFavorite: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText).first);
        expect(richText.maxLines, 1);
        expect(richText.overflow, TextOverflow.ellipsis);
      },
    );

    testWidgets(
      'should show a filled star icon when the stock is already in the watchlist',
      (WidgetTester tester) async {
        await _pumpSearchResultRow(
          tester,
          result: _sampleResult,
          query: '',
          favoriteSymbols: {'005930'},
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SvgPicture &&
                (widget.bytesLoader as SvgAssetLoader).assetName ==
                    'assets/icons/ico_star_filled.svg',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show an empty star icon when the stock is not in the watchlist',
      (WidgetTester tester) async {
        await _pumpSearchResultRow(tester, result: _sampleResult, query: '');

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SvgPicture &&
                (widget.bytesLoader as SvgAssetLoader).assetName ==
                    'assets/icons/ico_star.svg',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should call onToggleFavorite with the symbol when the star icon is tapped',
      (WidgetTester tester) async {
        String? tappedSymbol;

        await _pumpSearchResultRow(
          tester,
          result: _sampleResult,
          query: '',
          onToggleFavorite: (symbol) => tappedSymbol = symbol,
        );

        await tester.tap(find.byType(SvgPicture));
        await tester.pump();

        expect(tappedSymbol, '005930');
      },
    );
  });
}
