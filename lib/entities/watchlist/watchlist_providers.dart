import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../quote/quote_providers.dart';
import '../stock_meta/stock_meta_providers.dart';
import 'local_watchlist_repository.dart';
import 'watchlist_item.dart';
import 'watchlist_notifier.dart';
import 'watchlist_repository.dart';

/// main()에서 overrideWithValue로 주입되는 것을 전제합니다.
/// 기본 구현이 없으므로 override 없이 read하면 예외를 던집니다.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider는 main()에서 overrideWithValue로 주입되어야 합니다.',
  );
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return LocalWatchlistRepository(ref.watch(sharedPreferencesProvider));
});

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, Set<String>>((ref) {
  return WatchlistNotifier(ref.watch(watchlistRepositoryProvider));
});

/// 관심등록된 symbol 목록에 StockMeta·Quote를 결합해 반환합니다.
///
/// - `watchlistProvider`(symbol Set)를 `ref.watch`해 관심 상태가 바뀌면 자동 재계산된다.
/// - symbol이 비어 있으면 네트워크 호출 없이 빈 리스트를 즉시 반환한다.
/// - StockMeta는 symbol별로 개별 조회한다(현재 StockMetaRepository에 배치 조회가 없음).
/// - Quote는 `quoteRepositoryProvider.fetchQuotes(symbols)`로 전체 symbol을 한 번에 조회한다.
/// - 특정 symbol의 Quote가 응답 Map에 없으면 해당 WatchlistItem.quote는 null로 채운다.
final watchlistItemsProvider = FutureProvider<List<WatchlistItem>>((
  ref,
) async {
  final symbols = ref.watch(watchlistProvider);
  if (symbols.isEmpty) return const [];

  final stockMetaRepository = ref.watch(stockMetaRepositoryProvider);
  final quoteRepository = ref.watch(quoteRepositoryProvider);

  final symbolList = symbols.toList();
  final quotes = await quoteRepository.fetchQuotes(symbolList);
  final stockMetas = await Future.wait(
    symbolList.map(stockMetaRepository.fetchStockMeta),
  );

  return [
    for (final stockMeta in stockMetas)
      WatchlistItem(
        symbol: stockMeta.symbol,
        stockMeta: stockMeta,
        quote: quotes[stockMeta.symbol],
      ),
  ];
});

/// 단일 symbol의 관심등록 여부만 구독하는 경량 provider입니다.
/// 검색/상세 화면이 전체 WatchlistItem 목록(및 그에 딸린 Quote 네트워크 조회)을
/// 구독하지 않고도 관심 여부만 알 수 있도록 분리한다.
final isFavoriteProvider = Provider.family<bool, String>((ref, symbol) {
  return ref.watch(watchlistProvider).contains(symbol);
});
