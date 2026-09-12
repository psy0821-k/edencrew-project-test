# Issue #17 — [Phase2-2] WatchlistItem 조합 provider (Quote/StockMeta 결합)

> 참고: 이 문서 작성 시점에 이슈 #16(Watchlist 도메인 + LocalWatchlistRepository)은
> 아직 미구현 상태다(`lib/entities/watchlist/` 디렉터리 자체가 없음, 이슈 #16도 OPEN).
> 다만 #16 이슈 본문에 `WatchlistRepository`/`LocalWatchlistRepository`/`WatchlistNotifier`/
> `watchlistProvider`/`toggleFavorite`의 시그니처가 이미 상세히 확정되어 있으므로,
> 이 문서는 그 문서화된 계약을 그대로 전제하고 #17 범위(WatchlistItem 조합)만 설계한다.
> #16이 실제 구현되면 이 문서의 전제와 다른 부분이 없는지 한 번 더 대조가 필요하다.

## 시그니처

### `lib/entities/watchlist/watchlist_item.dart`

```dart
import '../quote/quote.dart';
import '../stock_meta/stock_meta.dart';

/// 관심등록된 종목 하나를 화면이 바로 렌더링할 수 있는 형태로 결합한 모델입니다.
class WatchlistItem {
  const WatchlistItem({
    required this.symbol,
    required this.stockMeta,
    required this.quote,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목 메타데이터 (종목명, 거래소명). 항상 값이 존재해야 한다.
  final StockMeta stockMeta;

  /// 실시간 시세. 아직 받아오지 못했거나 조회에 실패했으면 `null`.
  final Quote? quote;
}
```

- `dynamic`/암묵적 `any` 없음. `StockMeta`는 non-nullable(이슈 범위 밖 실패는 아래 "범위 배제" 참고),
  `Quote`는 nullable로 명시.
- `equals`/`hashCode`/`copyWith`는 이슈 범위에 없고 요구되지 않으므로 추가하지 않는다(YAGNI).

### `lib/entities/watchlist/watchlist_providers.dart` (기존 파일에 추가)

```dart
/// 관심등록된 symbol 목록에 StockMeta·Quote를 결합해 반환합니다.
///
/// - `watchlistProvider`(symbol Set)를 `ref.watch`해 관심 상태가 바뀌면 자동 재계산된다.
/// - symbol이 비어 있으면 네트워크 호출 없이 빈 리스트를 즉시 반환한다.
/// - StockMeta는 symbol별로 개별 조회한다(현재 StockMetaRepository에 배치 조회가 없음 — #17 범위 밖).
/// - Quote는 `quoteRepositoryProvider.fetchQuotes(symbols)`로 전체 symbol을 한 번에 조회한다
///   (naver-data-layer 요구사항 재사용, 개별 호출 금지).
/// - 특정 symbol의 Quote가 응답 Map에 없으면(조회 실패/누락) 해당 WatchlistItem.quote는 null로
///   채우고, 나머지 항목은 정상 반환한다 — Quote 실패가 전체 목록을 실패시키지 않는다.
final watchlistItemsProvider = FutureProvider<List<WatchlistItem>>((ref) async {
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
/// 구독하지 않고도 관심 여부만 알 수 있도록 분리한다 (PRD ADR 2).
final isFavoriteProvider = Provider.family<bool, String>((ref, symbol) {
  return ref.watch(watchlistProvider).contains(symbol);
});
```

### 에러 케이스

- `watchlistItemsProvider`는 **StockMeta 조회 실패를 처리하지 않는다** — 아래 "범위 배제" 참고.
  StockMeta 조회가 실패하면 `Future.wait`가 실패하고 provider 전체가 `AsyncValue.error`가 된다
  (기존 `Failure` 계층의 예외를 그대로 전파 — 새 에러 타입 도입 없음).
- Quote 조회는 `fetchQuotes`가 통째로 실패하는 경우(예: 네트워크 실패)와, 통째로는 성공했지만
  특정 symbol만 응답에 없는 경우를 구분해야 한다. AC는 후자("응답에 없을 때")만 명시하므로,
  이 이슈는 **후자만 책임진다** — 없는 symbol은 `quotes[symbol]`이 `null`을 반환하는 `Map` 조회
  특성을 그대로 활용해 `WatchlistItem.quote = null`로 채운다. `fetchQuotes` 자체가 예외를 던지는
  경우(완전 네트워크 장애)는 AC 범위 밖으로 보고 provider 전체 에러로 전파되도록 둔다(추가 방어
  로직 없음 — YAGNI, 필요해지면 별도 이슈로 분리).
- `isFavoriteProvider`는 에러 케이스가 없다(동기, `Set.contains`만 수행).

## 범위 배제 (자율 판단)

- **StockMeta 조회 실패 시나리오는 이 이슈 범위 밖으로 명시 배제한다.** 근거:
  - AC 5개 모두 Quote 실패/누락만 명시하고 StockMeta 실패는 언급이 없다.
  - 이슈 본문 "참고" 섹션도 "Quote가 없는 상태(`null`)는 화면 Phase의 스켈레톤 렌더링 조건"이라고만
    적어 Quote만 부분 실패 허용 대상으로 지목한다.
  - StockMeta는 종목명 등 화면의 핵심 식별 정보라, 이것이 없는 항목을 "부분적으로 렌더링 가능한
    상태"로 만드는 것 자체가 화면 설계(Phase 다음 단계) 영역이지 이 조합 provider의 책임이 아니다.
  - 가장 좁고 보수적인 해석 원칙에 따라, 실패 시 `watchlistItemsProvider` 전체를 에러로 전파하는
    (Riverpod `FutureProvider`의 기본 동작을 그대로 따르는) 것으로 확정한다. 필요해지면 후속 이슈에서
    재논의한다.
- **StockMeta 배치 조회 API도 범위 밖.** 현재 `StockMetaRepository.fetchStockMeta`는 단일 조회만
  제공한다. AC/이슈 본문 모두 StockMeta에 대해서는 "배치 조회" 요구가 없고 Quote에만 명시되어
  있으므로, `Future.wait`로 병렬 개별 호출한다(순차 호출은 아님 — 성능상 최소한의 배려는 하되,
  배치 API 신설은 하지 않는다).

## 테스트 시나리오

### `WatchlistItem`

- [정상] `symbol`, `stockMeta`, `quote`(non-null)로 생성하면 각 필드가 그대로 보관되어야 한다
- [정상] `quote`에 `null`을 전달해 생성하면 `quote` 필드가 `null`이어야 한다

### `watchlistItemsProvider`

- [정상] symbol 2개가 관심등록되어 있고 둘 다 정상 시세를 받을 수 있을 때, `watchlistItemsProvider`를
  구독하면 symbol별 StockMeta와 Quote가 결합된 `WatchlistItem` 2개가 반환되어야 한다 (AC 1)
- [정상] symbol 2개가 관심등록되어 있을 때, `watchlistItemsProvider`가 시세를 조회하면 `fetchQuotes`가
  symbol별로 각각 호출되지 않고 전체 symbol을 인자로 한 번만 호출되어야 한다 (AC 2)
- [경계] 관심등록된 symbol이 하나도 없을 때, `watchlistItemsProvider`를 구독하면 빈 리스트를
  반환하고 `fetchQuotes`/`fetchStockMeta`를 호출하지 않아야 한다
- [경계] 관심등록된 symbol이 1개일 때, `watchlistItemsProvider`를 구독하면 `WatchlistItem` 1개를
  포함한 리스트를 반환해야 한다
- [예외] 특정 symbol의 시세가 `fetchQuotes` 응답 Map에 없을 때, `watchlistItemsProvider`를 구독하면
  해당 `WatchlistItem.quote`는 `null`이고 나머지 항목은 정상(quote non-null)으로 반환되어야 한다 (AC 3)
- [예외] 관심등록된 모든 symbol의 시세가 `fetchQuotes` 응답 Map에 없을 때, `watchlistItemsProvider`를
  구독하면 모든 `WatchlistItem.quote`가 `null`이면서 리스트 길이는 symbol 개수와 같아야 한다
- [정상] `watchlistProvider`의 symbol 집합이 변경되면(`toggleFavorite` 등으로), `watchlistItemsProvider`가
  자동으로 재계산되어 변경된 symbol 집합을 반영한 목록을 반환해야 한다

### `isFavoriteProvider`

- [정상] symbol `"005930"`이 관심등록되어 있을 때, `isFavoriteProvider("005930")`을 구독하면
  `true`를 반환해야 한다 (AC 4)
- [경계] 관심등록되지 않은 symbol에 대해 `isFavoriteProvider`를 구독하면 `false`를 반환해야 한다
- [정상] `isFavoriteProvider("005930")`을 구독 중일 때 `toggleFavorite("005930")`으로 관심을
  해제하면, `isFavoriteProvider("005930")`이 별도 재구독 없이 자동으로 `false`로 갱신되어야 한다 (AC 5)
- [정상] `isFavoriteProvider("005930")`을 구독 중일 때 `toggleFavorite("005930")`으로 관심을
  등록하면, `isFavoriteProvider("005930")`이 자동으로 `true`로 갱신되어야 한다 (`isFavoriteProvider`가
  등록 방향 갱신도 동일하게 동작함을 확인 — AC 5의 대칭 케이스)

## AC 커버리지

| AC | 커버 시나리오 |
|---|---|
| 1. symbol 2개 정상 결합 | `watchlistItemsProvider` 정상 시나리오 1번째 |
| 2. fetchQuotes 배치 호출(개별 호출 금지) | `watchlistItemsProvider` 정상 시나리오 2번째 |
| 3. 특정 symbol 시세 실패 시 quote=null, 나머지 정상 | `watchlistItemsProvider` 예외 시나리오 1번째 |
| 4. isFavoriteProvider("005930") → true | `isFavoriteProvider` 정상 시나리오 1번째 |
| 5. toggleFavorite 해제 → isFavoriteProvider 자동 false 갱신 | `isFavoriteProvider` 정상 시나리오 2번째(해제) + 3번째(등록, 대칭 보강) |

5/5 AC 모두 최소 1개 이상의 시나리오로 커버됨. 추가로 경계 케이스(빈 목록, 전체 실패,
등록 방향 갱신)를 자율 보강해 견고성을 높였다.
