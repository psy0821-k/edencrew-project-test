# 이슈 2: WatchlistItem 조합 provider (Quote/StockMeta 결합)

## 목적

관심등록된 symbol 목록에 실시간 시세(Quote)와 종목 메타데이터(StockMeta)를 결합해, 관심 화면이 바로 렌더링할 수 있는 형태를 만든다. 검색/상세 화면이 개별 symbol의 관심 여부만 구독할 수 있는 경량 provider도 함께 제공한다. PRD ADR 2 참고.

## 구현 범위

`lib/entities/watchlist/`:

- `watchlist_item.dart` — `WatchlistItem` 모델
  - `symbol`, `stockMeta` (StockMeta), `quote` (Quote? — 아직 시세를 못 받아왔으면 `null`)
- `watchlist_providers.dart`에 추가:
  - `watchlistItemsProvider` — `FutureProvider<List<WatchlistItem>>`
    - `ref.watch(watchlistProvider)`(symbol Set)를 구독
    - 각 symbol의 StockMeta를 `stockMetaRepositoryProvider`로 조회
    - `quoteRepositoryProvider.fetchQuotes(symbols)`로 **한 번에 일괄 조회** (naver-data-layer 요구사항 재사용 — 개별 호출 금지)
    - Quote 조회 실패/아직 없는 symbol은 `quote: null`로 채워 `WatchlistItem` 생성 (에러로 전체 목록을 실패시키지 않음)
  - `isFavoriteProvider` — `Provider.family<bool, String>`, `ref.watch(watchlistProvider).contains(symbol)`

## 참고

- `entities/quote/quote_repository.dart`의 `fetchQuotes(List<String> symbols)`를 그대로 재사용한다 (이미 일괄조회로 구현되어 있음, naver-data-layer 이슈 #11).
- `entities/stock_meta/stock_meta_repository.dart`를 재사용한다.
- Quote가 없는 상태(`null`)는 화면 Phase의 스켈레톤 렌더링 조건으로 쓰인다 — 이 이슈는 `null`을 만드는 것까지만 책임진다.

## Acceptance Criteria

- [ ] Given symbol 2개가 관심등록되어 있고 둘 다 정상 시세를 받을 수 있을 때, When `watchlistItemsProvider`를 구독하면, Then symbol별 StockMeta와 Quote가 결합된 `WatchlistItem` 2개가 반환된다.
- [ ] Given symbol 2개가 관심등록되어 있고, When `watchlistItemsProvider`가 시세를 조회하면, Then `fetchQuotes`가 symbol별로 각각 호출되지 않고 한 번의 호출로 전체 symbol을 조회한다.
- [ ] Given 특정 symbol의 시세 조회가 실패하거나 응답에 없을 때, When `watchlistItemsProvider`를 구독하면, Then 해당 `WatchlistItem.quote`는 `null`이고 나머지 항목은 정상 반환된다 (전체 목록이 실패하지 않음).
- [ ] Given symbol `"005930"`이 관심등록되어 있을 때, When `isFavoriteProvider("005930")`을 구독하면, Then `true`를 반환한다.
- [ ] Given `isFavoriteProvider("005930")`을 구독 중일 때, When `toggleFavorite("005930")`으로 관심 해제하면, Then `isFavoriteProvider("005930")`이 자동으로 `false`로 갱신된다 (별도 재구독 없이 `ref.watch` 전파로 동작).
