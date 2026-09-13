import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/watchlist/watchlist_providers.dart';
import '../features/watchlist-list/watchlist_empty_view.dart';
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            WatchlistHeader(
              sortLabel: sortCriteria.label,
              onSortTap: () => showWatchlistSortSheet(context),
              onRefreshTap: () {
                ref.read(watchlistRefreshPendingProvider.notifier).run(() {
                  ref.invalidate(watchlistItemsProvider);
                  return ref.read(watchlistItemsProvider.future);
                });
              },
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  // 새로고침 중에도 이전 목록을 유지한다.
                  // (개별 행의 시세 갱신 표시는 WatchlistRow가 quote == null일 때 스켈레톤으로 처리)
                  final items = itemsAsync.value;

                  if (items != null) {
                    if (items.isEmpty) return const WatchlistEmptyView();
                    final sorted = sortWatchlistItems(items, sortCriteria);
                    return ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, index) =>
                          WatchlistRow(item: sorted[index]),
                    );
                  }

                  return itemsAsync.when(
                    data: (_) => const SizedBox.shrink(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    // TODO: 에러 처리 — spec-fixed.md의 배너/전체 에러 뷰 분기는 이후 구현
                    error: (error, stackTrace) => Center(child: Text('$error')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
