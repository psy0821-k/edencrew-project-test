import '../../entities/quote/quote.dart';
import '../../entities/watchlist/watchlist_item.dart';
import 'sort_criteria.dart';

/// [items]를 [criteria] 기준으로 정렬한 새 리스트를 반환하는 순수 함수.
///
/// - `priceDesc`/`changeRateDesc`: `quote == null`인 항목은 항상 결과의 맨 뒤로 보낸다.
/// - `nameAsc`: `stockMeta.name`은 항상 값이 존재하므로 null 처리가 필요 없다.
/// - `items`를 변경하지 않고 정렬된 새 리스트를 반환한다(원본 비파괴).
List<WatchlistItem> sortWatchlistItems(
  List<WatchlistItem> items,
  SortCriteria criteria,
) {
  final sorted = List<WatchlistItem>.of(items);
  switch (criteria) {
    case SortCriteria.priceDesc:
      sorted.sort((a, b) => _compareByQuoteDesc(a, b, (quote) => quote.currentPrice));
    case SortCriteria.changeRateDesc:
      sorted.sort((a, b) => _compareByQuoteDesc(a, b, (quote) => quote.changeRate));
    case SortCriteria.nameAsc:
      sorted.sort(_byNameAsc);
  }
  return sorted;
}

/// [quote]가 없는 항목은 결과의 맨 뒤로 보내고, 나머지는 [selector]로 뽑은 값을
/// 내림차순 비교하는 공통 로직. `priceDesc`/`changeRateDesc`가 이 로직을 공유한다.
int _compareByQuoteDesc(
  WatchlistItem a,
  WatchlistItem b,
  num Function(Quote quote) selector,
) {
  if (a.quote == null && b.quote == null) return 0;
  if (a.quote == null) return 1;
  if (b.quote == null) return -1;
  return selector(b.quote!).compareTo(selector(a.quote!));
}

int _byNameAsc(WatchlistItem a, WatchlistItem b) {
  return a.stockMeta.name.compareTo(b.stockMeta.name);
}
