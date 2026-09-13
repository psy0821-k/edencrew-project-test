# Issue #56 — 상세 화면 헤더 + 현재가/등락 + 관심 버튼

## 디자인 수정 (Green 이후 반영, 원 스펙 변경)

- 뒤로가기 아이콘: `assets/icons/ico_back.svg` 사용(기본 `BackButton` 대신)
- 현재가 + 등락률: 같은 줄에 하단(baseline) 기준으로 배치
- 관심 버튼 토글 시 검색 화면과 동일한 `showFavoriteToast` 재사용 — **PRD/spec-fixed의 "토스트 없음" 방침을 이 이슈에서 변경**
- 타이포 스펙
  - title(종목명): Medium, 15px, 행간 20px, 자간 -0.1px, `text/primary`
  - caption(종목코드·시장): Regular, 11px, 행간 14px, `text/secondary`
  - 현재가: Bold, 30px, 행간 36px, 자간 -0.4px, `text/primary`
  - 등락률(하락): Medium, 15px, 행간 20px, 자간 -0.1px, `price/down/text`
  - 등락률(상승): 동일 스펙, `price/up/text`

## 시그니처

```dart
// lib/entities/quote/quote_providers.dart (추가)
/// 단일 symbol의 시세를 조회한다. 헤더/상세 화면 전용.
/// 내부적으로 quoteRepositoryProvider.fetchQuotes([symbol])을 감싸고,
/// 응답 Map에 symbol이 없으면(빈 결과) EmptyResultFailure를 던진다.
final quoteProvider = FutureProvider.family<Quote, String>((ref, symbol) async {
  final repository = ref.watch(quoteRepositoryProvider);
  final result = await repository.fetchQuotes([symbol]);
  final quote = result[symbol];
  if (quote == null) throw const EmptyResultFailure();
  return quote;
});

// lib/entities/stock_meta/stock_meta_providers.dart (추가)
/// 단일 symbol의 메타데이터를 조회한다. 헤더/상세 화면 전용.
final stockMetaProvider = FutureProvider.family<StockMeta, String>((ref, symbol) async {
  final repository = ref.watch(stockMetaRepositoryProvider);
  return repository.fetchStockMeta(symbol);
});
```

```dart
// lib/pages/stock_detail_page.dart (교체)
/// 종목 상세 화면. 헤더(뒤로가기/종목명/종목코드·시장/관심 버튼) +
/// 현재가·등락을 표시한다. 기간 탭/차트/표는 이슈 #57 이후 범위.
class StockDetailPage extends ConsumerWidget {
  const StockDetailPage({required this.symbol, super.key});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

```dart
// lib/features/stock-detail/stock_detail_header.dart (신규)
/// 상세 화면 상단 고정 헤더. 뒤로가기 + 종목명 + "종목코드 · 시장" + 관심 버튼.
/// StockMeta 로딩 전에는 종목명/시장 영역을 SkeletonBox로 표시한다.
class StockDetailHeader extends ConsumerWidget {
  const StockDetailHeader({
    super.key,
    required this.symbol,
    required this.stockMeta, // AsyncValue<StockMeta>
  });

  final String symbol;
  final AsyncValue<StockMeta> stockMeta;

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

```dart
// lib/features/stock-detail/stock_detail_price_section.dart (신규)
/// 현재가 + 등락(방향 아이콘 ▲/▼ + formatPriceChange 색상/텍스트) 표시.
class StockDetailPriceSection extends StatelessWidget {
  const StockDetailPriceSection({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) { ... }
}
```

```dart
// lib/features/stock-detail/stock_detail_error_view.dart (신규)
/// 최초 조회(quote/stockMeta) 실패 시 헤더 아래 영역 전체를 대체하는
/// 에러 뷰. WatchlistErrorView와 동일 패턴, 상세 화면 전용 문구.
class StockDetailErrorView extends StatelessWidget {
  const StockDetailErrorView({super.key, required this.onRetryTap});

  final VoidCallback onRetryTap;

  @override
  Widget build(BuildContext context) { ... }
}
```

### 동작 방식

- `StockDetailPage`가 `stockMetaProvider(symbol)`, `quoteProvider(symbol)`을 각각 `ref.watch`한다.
- `StockDetailHeader`는 `AsyncValue<StockMeta>`를 받아 loading일 때 종목명/시장 자리만 `SkeletonBox`로 대체한다. 뒤로가기 버튼은 항상 즉시 표시된다(AC "헤더는 즉시 표시" 충족).
- 본문(현재가/등락)은 `quote`와 `stockMeta` 상태를 조합해 분기한다.
  - 둘 중 하나라도 loading → 헤더 아래 영역 `SkeletonBox`
  - 둘 중 하나라도 error → 헤더는 유지, `StockDetailErrorView` (다시 시도 시 `quoteProvider`/`stockMetaProvider` 둘 다 `ref.invalidate`)
  - 둘 다 data → `StockDetailPriceSection`
- 관심 버튼: `SearchResultRow`와 동일 패턴 — `isFavoriteProvider(symbol)` watch + `pendingSymbolsProvider.notifier.run` + `watchlistProvider.notifier.toggleFavorite` (토스트 없음, `SearchPage._onToggleFavorite`에서 토스트 호출만 뺀 버전).
- `quoteProvider`/`stockMetaProvider`는 자체 에러를 만들지 않고 하위 Repository가 던지는 `NetworkFailure`/`EmptyResultFailure`를 그대로 전파한다(`watchlistItemsProvider`와 동일 패턴).

## 테스트 시나리오

### quoteProvider

- [정상] symbol을 조회하면 `quoteRepositoryProvider.fetchQuotes([symbol])`을 호출해 해당 symbol의 `Quote`를 반환한다
- [예외] 응답 Map에 symbol이 없으면 `EmptyResultFailure`를 던진다
- [예외] `quoteRepositoryProvider.fetchQuotes`가 `NetworkFailure`를 던지면 그대로 전파한다

### stockMetaProvider

- [정상] symbol을 조회하면 `stockMetaRepositoryProvider.fetchStockMeta(symbol)`을 호출해 `StockMeta`를 반환한다
- [예외] `stockMetaRepositoryProvider.fetchStockMeta`가 `NetworkFailure`를 던지면 그대로 전파한다

### StockDetailHeader

- [정상] `stockMeta`가 data 상태면 종목명과 "종목코드 · 시장"이 표시된다
- [정상] `stockMeta`가 loading 상태여도 뒤로가기 버튼은 즉시 표시된다
- [경계] `stockMeta`가 loading 상태면 종목명/시장 자리에 `SkeletonBox`가 표시된다
- [정상] 뒤로가기 버튼을 탭하면 이전 화면으로 돌아간다(`Navigator.pop` 호출)
- [정상] `isFavoriteProvider(symbol)`이 false면 빈 별 아이콘, true면 채워진 별 아이콘이 표시된다
- [정상] 관심 버튼을 탭하면 `watchlistProvider.notifier.toggleFavorite(symbol)`이 호출되고 토스트는 노출되지 않는다
- [경계] 관심 버튼을 연속으로 빠르게 탭하면(`pendingSymbolsProvider`가 pending 상태) 두 번째 탭은 무시된다

### StockDetailPriceSection

- [정상] `Quote`가 주어지면 현재가가 콤마 포맷으로 표시된다
- [정상] `changeAmount`가 양수면 상승 아이콘(▲)과 `priceUpText` 색상으로 등락이 표시된다
- [정상] `changeAmount`가 음수면 하락 아이콘(▼)과 `priceDownText` 색상으로 등락이 표시된다
- [경계] `changeAmount`가 0이면 보합 상태(`priceFlatText` 색상, 방향 아이콘 없음 또는 중립 아이콘)로 표시된다

### StockDetailPage (통합)

- [정상] 검색 화면에서 종목 행을 탭해 진입하면 뒤로가기/종목명/종목코드·시장/관심 버튼이 있는 헤더가 보인다
- [정상] `quoteProvider`/`stockMetaProvider` 조회가 완료되면 현재가와 등락(부호+색상+방향 아이콘)이 표시된다
- [정상] 관심등록 안 된 종목 상세에서 관심 버튼을 탭하면 별 아이콘이 즉시 채워지고(토스트 없음), `watchlistProvider` 상태에도 symbol이 반영되어 관심 화면 목록에도 나타난다
- [경계] `quoteProvider`/`stockMetaProvider`가 아직 loading이면 헤더 아래 영역에 `SkeletonBox`가 표시된다
- [예외] `quoteProvider` 또는 `stockMetaProvider` 조회가 최초에 실패하면 헤더는 유지된 채 그 아래가 `StockDetailErrorView`(다시 시도 버튼 포함)로 대체된다
- [예외] `StockDetailErrorView`의 다시 시도 버튼을 탭하면 `quoteProvider`/`stockMetaProvider`가 재조회된다

## AC 커버리지

| AC | 커버하는 시나리오 |
|---|---|
| 헤더(뒤로가기/종목명/종목코드·시장/관심 버튼) 표시 | StockDetailPage 통합 1번, StockDetailHeader 시나리오 전반 |
| 현재가·등락(부호+색상+방향 아이콘) 표시 | StockDetailPage 통합 2번, StockDetailPriceSection 시나리오 전반 |
| 관심 버튼 탭 → 즉시 반영(토스트 없음) + 관심 화면 동기화 | StockDetailPage 통합 3번, StockDetailHeader 관심 버튼 시나리오 |
| 데이터 도착 전 스켈레톤 표시 | StockDetailPage 통합 4번, StockDetailHeader loading 시나리오 |
| 최초 조회 실패 시 헤더 유지 + 에러 뷰 | StockDetailPage 통합 5, 6번 |
