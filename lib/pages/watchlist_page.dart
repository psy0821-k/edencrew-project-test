import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/watchlist/watchlist_item.dart';
import '../entities/watchlist/watchlist_providers.dart';
import '../features/watchlist-list/watchlist_empty_view.dart';
import '../features/watchlist-list/watchlist_error_banner.dart';
import '../features/watchlist-list/watchlist_error_view.dart';
import '../features/watchlist-list/watchlist_header.dart';
import '../features/watchlist-list/watchlist_row.dart';
import '../features/watchlist-sort/sort_criteria.dart';
import '../features/watchlist-sort/watchlist_comparator.dart';
import '../features/watchlist-sort/watchlist_sort_provider.dart';
import '../features/watchlist-sort/watchlist_sort_sheet.dart';
import '../shared/state/pending_flag_notifier.dart';

/// 관심 화면. 헤더는 [WatchlistHeader], 빈 상태는 [WatchlistEmptyView]로 교체됐다.
/// 목록은 [watchlistItemsProvider]를 구독한다.
class WatchlistPage extends ConsumerWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(watchlistItemsProvider);
    final sortCriteria = ref.watch(watchlistSortCriteriaProvider);
    final isRefreshing = ref.watch(watchlistRefreshPendingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            WatchlistHeader(
              sortLabel: sortCriteria.label,
              onSortTap: () => showWatchlistSortSheet(context),
              onRefreshTap: () => _refresh(ref),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  // 새로고침 중에도 이전 목록을 유지한다.
                  // (개별 행의 시세 갱신 표시는 WatchlistRow가 quote == null일 때 스켈레톤으로 처리)
                  // AsyncValue.value는 에러 상태일 때 저장된 예외를 그대로
                  // 던지므로(Riverpod 기본 동작), valueOrNull로 안전하게 꺼낸다.
                  final items = itemsAsync.valueOrNull;

                  if (items != null) {
                    if (items.isEmpty) return const WatchlistEmptyView();
                    // 새로고침 진행 중에는 이전 시세를 그대로 보여주는 대신,
                    // WatchlistRow가 quote == null일 때 처리하는 스켈레톤을
                    // 재사용해 실제로 다시 조회 중임을 알린다.
                    final displayItems = isRefreshing
                        ? [
                            for (final item in items)
                              WatchlistItem(
                                symbol: item.symbol,
                                stockMeta: item.stockMeta,
                                quote: null,
                              ),
                          ]
                        : items;
                    final sorted = sortWatchlistItems(
                      displayItems,
                      sortCriteria,
                    );
                    final list = ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, index) =>
                          WatchlistRow(item: sorted[index]),
                    );

                    // 이전 데이터가 있는 상태에서 재조회가 실패하면, 목록은
                    // 유지한 채 상단에 얇은 경고 배너만 노출한다.
                    if (itemsAsync.hasError) {
                      return Column(
                        children: [
                          WatchlistErrorBanner(
                            onRetryTap: () => _refresh(ref),
                          ),
                          Expanded(child: list),
                        ],
                      );
                    }
                    return list;
                  }

                  return itemsAsync.when(
                    data: (_) => const SizedBox.shrink(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    // 표시할 이전 데이터 자체가 없는 첫 로드 실패는 목록
                    // 영역 전체를 에러 상태로 대체한다(헤더·탭바는 유지).
                    error: (error, stackTrace) =>
                        WatchlistErrorView(onRetryTap: () => _refresh(ref)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    // 실패 시에도 watchlistItemsProvider의 AsyncValue 자체가 에러 상태를
    // 담아 build()가 그걸로 배너/에러 뷰를 그리므로, 여기서는 재조회를
    // 시작시키는 역할만 하고 예외는 흡수한다.
    ref
        .read(watchlistRefreshPendingProvider.notifier)
        .run(() {
          ref.invalidate(watchlistItemsProvider);
          return ref.read(watchlistItemsProvider.future);
        })
        .catchError((_) {});
  }
}
