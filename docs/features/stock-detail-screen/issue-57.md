# Issue #57 — 기간 탭 + 요약 카드 + 일별 시세 표

## 시그니처

### 1. 상태/Provider

```dart
// lib/entities/daily_quote/daily_quote_providers.dart (추가)
/// 상세 화면에서 현재 선택된 기간 탭. 기본값 oneMonth.
final selectedPeriodProvider = StateProvider<Period>((ref) => Period.oneMonth);

/// (symbol, period) 조합의 일별 시세를 조회한다. 차트·요약 카드·표 전용.
/// 헤더(quoteProvider/stockMetaProvider)와 독립적이라 기간 전환이 헤더를 리빌드하지 않는다.
final dailyQuoteProvider =
    FutureProvider.family<List<DailyQuote>, (String symbol, Period period)>((
  ref,
  args,
) async {
  final repository = ref.watch(dailyQuoteRepositoryProvider);
  return repository.fetchQuotes(args.$1, args.$2);
});
```

```dart
// lib/features/stock-detail/stock_detail_daily_quote_notifier.dart (신규)
/// dailyQuoteProvider를 감싸 "기존 데이터 유지 + 요청 세대 검증"을 구현하는 Notifier.
/// SearchDebouncerNotifier와 동일한 세대 카운터 패턴으로 race condition을 막는다.
/// - 탭 전환 시 즉시 새 Future를 시작하되, state는 이전 AsyncData를 유지한 채
///   isRefreshing 플래그만 별도로 노출해 "화면을 비우지 않는" stale-while-revalidate를 구현한다.
class StockDetailDailyQuoteState {
  const StockDetailDailyQuoteState({
    required this.quotes, // 마지막으로 성공한 List<DailyQuote> (초기 null)
    required this.isRefreshing,
    required this.error, // 탭 전환 중 실패 시에만 채워짐(기존 quotes는 유지)
  });

  final List<DailyQuote>? quotes;
  final bool isRefreshing;
  final Object? error;
}

class StockDetailDailyQuoteNotifier extends FamilyNotifier<StockDetailDailyQuoteState, String> {
  // symbol을 family 파라미터로 받고, ref.watch(selectedPeriodProvider)를 구독해
  // 기간이 바뀔 때마다 fetch를 다시 트리거한다.
  // 요청마다 세대 번호를 증가시키고, 응답 도착 시 최신 세대인지 확인 후에만 state 반영.
}

final stockDetailDailyQuoteProvider = NotifierProvider.family<
    StockDetailDailyQuoteNotifier, StockDetailDailyQuoteState, String>(
  StockDetailDailyQuoteNotifier.new,
);
```

### 2. 기간 탭 UI

```dart
// lib/features/stock-detail/stock_detail_period_tabs.dart (신규)
/// 1개월/3개월/6개월/1년 탭. 선택된 탭은 accentDefault(텍스트)/accentBg(배경).
class StockDetailPeriodTabs extends ConsumerWidget {
  const StockDetailPeriodTabs({super.key});
  // ref.watch(selectedPeriodProvider) 읽고, 탭 탭 시 ref.read(selectedPeriodProvider.notifier).state = period
}
```

### 3. 일별 시세 등락 계산 + 요약 카드

```dart
// lib/shared/utils/daily_quote_change_formatter.dart (신규)
/// 인접한 두 거래일 DailyQuote의 종가를 비교해 등락을 계산한다.
/// [current]가 그 행, [previous]가 하루 전 행(배열상 다음 인덱스, 최신순 정렬 기준).
/// previous가 null이면(그 기간의 마지막 행) 등락을 표시하지 않는다(text: '-').
PriceChangeDisplay? formatDailyQuoteChange(
  DailyQuote current,
  DailyQuote? previous,
  AppColors colors,
);
```

```dart
// lib/features/stock-detail/stock_detail_summary_card.dart (신규)
/// 시가/고가/저가(그대로) + 거래량(NumberFormatter.compactKorean) +
/// 시가총액(Quote.marketCap을 compactKorean) 카드.
/// 시가총액은 Quote에서, 나머지는 최신 DailyQuote(quotes.first)에서 가져온다.
class StockDetailSummaryCard extends StatelessWidget {
  const StockDetailSummaryCard({
    super.key,
    required this.latestDailyQuote,
    required this.marketCap,
  });

  final DailyQuote latestDailyQuote;
  final int marketCap;
}
```

### 4. 일별 시세 표 + 탭 전환 에러 배너

```dart
// lib/features/stock-detail/stock_detail_daily_quote_table.dart (신규)
/// 날짜(MM.dd)/종가/등락/거래량 컬럼의 표. quotes를 최신순 그대로 렌더링.
class StockDetailDailyQuoteTable extends StatelessWidget {
  const StockDetailDailyQuoteTable({super.key, required this.quotes});
  final List<DailyQuote> quotes;
}
```

```dart
// lib/features/stock-detail/stock_detail_period_error_banner.dart (신규)
/// 탭 전환 중 실패 시 표/카드 위에 얇게 노출하는 배너.
/// WatchlistErrorBanner와 동일 패턴, 상세 화면 전용 문구.
class StockDetailPeriodErrorBanner extends StatelessWidget {
  const StockDetailPeriodErrorBanner({super.key, required this.onRetryTap});
  final VoidCallback onRetryTap;
}
```

### StockDetailPage 조합

`StockDetailPage`가 `StockDetailPeriodTabs` + (에러 배너 조건부) + `StockDetailSummaryCard` + `StockDetailDailyQuoteTable`을 헤더/현재가 아래에 이어 붙인다. 캔들 차트 자리는 이슈 #58에서 채워질 빈 공간으로 남겨둔다(레이아웃 순서만 잡아둠, 실제 위젯은 넣지 않음).

기존 재사용: `NumberFormatter.compactKorean`(거래량/시가총액 축약, 이미 구현됨), `DateFormatter.internalToDisplay`(날짜 표시, 이미 구현됨), `Quote.marketCap`(이미 구현됨).

## 테스트 시나리오

### selectedPeriodProvider

- [정상] 기본값은 `Period.oneMonth`다

### dailyQuoteProvider

- [정상] (symbol, period)로 조회하면 `dailyQuoteRepositoryProvider.fetchQuotes(symbol, period)`를 호출해 결과를 반환한다

### StockDetailDailyQuoteNotifier

- [정상] symbol을 구독하면 `selectedPeriodProvider`의 현재 기간으로 최초 조회를 수행하고 `quotes`에 결과가 채워진다
- [정상] `selectedPeriodProvider`가 바뀌면 자동으로 새 기간의 데이터를 다시 조회한다
- [경계] 새 기간 조회 중에는 `isRefreshing`이 true가 되지만 `quotes`는 이전 값을 그대로 유지한다(화면 비우지 않음)
- [경계] `oneMonth` 조회 직후 바로 `oneYear`로 전환해 두 요청이 겹치면, 두 응답이 모두 도착한 뒤 최종 `quotes`는 마지막으로 선택한 `oneYear`의 데이터만 반영된다(오래된 응답 무시, 세대 검증)
- [예외] 탭 전환 중 조회가 실패하면 `error`에 값이 채워지고 `quotes`는 이전 값을 그대로 유지한다
- [예외] 최초 조회(quotes가 아직 없는 상태)가 실패하면 `error`에 값이 채워지고 `quotes`는 null로 유지된다

### formatDailyQuoteChange

- [정상] `current.closePrice`가 `previous.closePrice`보다 크면 양수 등락 + `priceUpText` 색상을 반환한다
- [정상] `current.closePrice`가 `previous.closePrice`보다 작으면 음수 등락 + `priceDownText` 색상을 반환한다
- [경계] 두 종가가 같으면 등락 0 + `priceFlatText` 색상을 반환한다
- [경계] `previous`가 null이면(그 기간의 마지막 행) 등락을 표시하지 않는다(null 반환 또는 '-' 텍스트)

### StockDetailPeriodTabs

- [정상] `selectedPeriodProvider`가 `oneMonth`면 `1개월` 탭이 `accentDefault`/`accentBg` 스타일로 표시된다
- [정상] `3개월` 탭을 탭하면 `selectedPeriodProvider`가 `threeMonths`로 바뀐다
- [정상] 탭을 전환하면 이전에 선택됐던 탭은 스타일이 원래대로 돌아간다

### StockDetailSummaryCard

- [정상] 시가/고가/저가가 `DailyQuote`의 값 그대로 표시된다
- [정상] 거래량이 `NumberFormatter.compactKorean`으로 축약되어 표시된다(예: `29,113천`)
- [정상] 시가총액이 `NumberFormatter.compactKorean`으로 축약되어 표시된다(예: `1,063조`)

### StockDetailDailyQuoteTable

- [정상] 날짜가 `MM.dd` 형식으로 표시된다
- [정상] 각 행의 등락이 `formatDailyQuoteChange` 결과(부호+색상)로 표시된다
- [경계] 목록의 마지막 행(그 기간의 가장 오래된 데이터)은 다음 인덱스가 없어 등락이 표시되지 않는다

### StockDetailPage (통합)

- [정상] 상세 화면에 진입해 데이터가 도착하면 `1개월` 탭이 선택된 상태로 요약 카드와 일별 시세 표가 표시된다
- [정상] `1개월` 탭에서 `3개월` 탭을 누르면 표/카드가 3개월치 데이터로 바뀐다
- [경계] 탭 전환 요청이 진행 중인 동안에는 기존 표/카드가 화면에서 사라지지 않는다
- [경계] `1개월`을 누른 직후 바로 `1년`을 눌러 두 요청이 겹치면, 최종 화면에는 `1년`(마지막으로 누른 탭)의 데이터만 반영된다
- [예외] 기간 탭 전환 중 조회가 실패하면 기존 표/카드는 유지된 채 상단에 에러 배너와 다시 시도 버튼이 표시된다

## AC 커버리지

| AC | 커버하는 시나리오 |
|---|---|
| 진입 시 `1개월` 탭 선택 상태로 요약 카드·표 표시 | StockDetailPage 통합 1번 |
| `3개월` 탭 전환 시 스타일 이동 + 데이터 교체 | StockDetailPeriodTabs 1~3번, StockDetailPage 통합 2번 |
| 탭 전환 중 기존 표/카드 유지(화면 비우지 않음) | StockDetailDailyQuoteNotifier 경계 3번, StockDetailPage 통합 3번 |
| 빠른 연속 전환 시 마지막 탭 데이터만 반영(race condition) | StockDetailDailyQuoteNotifier 경계 4번, StockDetailPage 통합 4번 |
| 일별 시세 표 등락(인접 거래일 종가 비교, 부호+색) | formatDailyQuoteChange 전체, StockDetailDailyQuoteTable 2번 |
| 거래량/시가총액 축약 표기(`29,113천`, `1,063조`) | StockDetailSummaryCard 2~3번 |
| 탭 전환 중 실패 시 표/카드 유지 + 에러 배너 + 다시 시도 | StockDetailDailyQuoteNotifier 예외 1번, StockDetailPage 통합 5번 |
