import 'dart:async';

import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_header.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({Set<String>? initialSymbols, this.toggleDelay})
    : _symbols = initialSymbols ?? {};

  final Set<String> _symbols;
  final Future<void>? toggleDelay;
  int toggleCallCount = 0;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async {
    toggleCallCount++;
    if (toggleDelay != null) await toggleDelay;
    final nowFavorite = !_symbols.contains(symbol);
    if (nowFavorite) {
      _symbols.add(symbol);
    } else {
      _symbols.remove(symbol);
    }
    return nowFavorite;
  }
}

const _sampleStockMeta = StockMeta(
  symbol: '005930',
  name: '삼성전자',
  marketName: '코스피',
);

Future<_FakeWatchlistRepository> _pumpHeader(
  WidgetTester tester, {
  AsyncValue<StockMeta>? stockMeta,
  Set<String>? initialFavoriteSymbols,
  Future<void>? toggleDelay,
}) async {
  final fake = _FakeWatchlistRepository(
    initialSymbols: initialFavoriteSymbols,
    toggleDelay: toggleDelay,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(fake),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: StockDetailHeader(
            symbol: '005930',
            stockMeta: stockMeta ?? const AsyncValue.data(_sampleStockMeta),
          ),
        ),
      ),
    ),
  );
  return fake;
}

Finder _starIconFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SvgPicture &&
        (widget.bytesLoader as SvgAssetLoader).assetName.contains('star'),
  );
}

void main() {
  group('StockDetailHeader', () {
    testWidgets('stockMeta가 data 상태면 종목명과 "종목코드 · 시장"이 표시된다', (tester) async {
      await _pumpHeader(tester);

      expect(find.text('삼성전자'), findsOneWidget);
      expect(find.textContaining('005930'), findsOneWidget);
      expect(find.textContaining('코스피'), findsOneWidget);
    });

    testWidgets('하단에 borderSubtle 색상의 1px 보더가 표시된다', (tester) async {
      await _pumpHeader(tester);

      final context = tester.element(find.byType(StockDetailHeader));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StockDetailHeader),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border?.bottom.width, 1);
      expect(decoration.border?.bottom.color, context.colors.borderSubtle);
    });

    testWidgets('stockMeta가 loading 상태여도 뒤로가기 버튼은 즉시 표시된다', (tester) async {
      await _pumpHeader(tester, stockMeta: const AsyncValue.loading());

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/icons/ico_back.svg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('stockMeta가 loading 상태면 종목명/시장 자리에 SkeletonBox가 표시된다', (
      tester,
    ) async {
      await _pumpHeader(tester, stockMeta: const AsyncValue.loading());

      expect(find.text('삼성전자'), findsNothing);
      final skeletonFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'SkeletonBox',
      );
      expect(skeletonFinder, findsWidgets);
    });

    testWidgets('뒤로가기 버튼을 탭하면 이전 화면으로 돌아간다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              _FakeWatchlistRepository(),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: StockDetailHeader(
                            symbol: '005930',
                            stockMeta: const AsyncValue.data(_sampleStockMeta),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(StockDetailHeader), findsOneWidget);

      final backButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            (widget.bytesLoader as SvgAssetLoader).assetName ==
                'assets/icons/ico_back.svg',
      );
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(StockDetailHeader), findsNothing);
    });

    testWidgets('isFavoriteProvider가 false면 빈 별 아이콘이 표시된다', (tester) async {
      await _pumpHeader(tester);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/icons/ico_star.svg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('isFavoriteProvider가 true면 채워진 별 아이콘이 표시된다', (tester) async {
      await _pumpHeader(tester, initialFavoriteSymbols: {'005930'});

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/icons/ico_star_filled.svg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('관심 버튼을 탭하면 toggleFavorite이 호출되고 관심 등록 토스트가 노출된다', (
      tester,
    ) async {
      final fake = await _pumpHeader(tester);

      await tester.tap(_starIconFinder());
      await tester.pumpAndSettle();

      expect(fake.toggleCallCount, 1);
      expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    });

    testWidgets('관심 버튼을 연속으로 빠르게 탭하면 두 번째 탭은 무시된다', (tester) async {
      final delayCompleter = Completer<void>();
      final fake = await _pumpHeader(
        tester,
        toggleDelay: delayCompleter.future,
      );

      await tester.tap(_starIconFinder());
      await tester.pump();
      await tester.tap(_starIconFinder());
      await tester.pump();

      delayCompleter.complete();
      await tester.pumpAndSettle();

      expect(fake.toggleCallCount, 1);
    });
  });
}
