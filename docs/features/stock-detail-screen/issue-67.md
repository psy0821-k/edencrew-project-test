# Issue #67 — 죽은 코드 제거 및 UI 엣지케이스 보완

이슈 하나에 3개 영역(naver-data-layer, stock-detail-screen, search-screen)의 소규모
개선이 묶여 있다.

## 시그니처

### 1. canonicalId 제거 (naver-data-layer)

```dart
// lib/entities/search/search_result.dart
class SearchResult {
  const SearchResult({
    required this.symbol,
    required this.name,
    required this.marketName,
  });

  final String symbol;
  final String name;
  final String marketName;
  // canonicalId 게터 제거 (YAGNI — 국내 주식 전용 범위에서 시장 구분자로 쓰이지 않음)
}
```

### 2. 일별 시세 표 마지막 행 등락 표시 (stock-detail-screen)

```dart
// lib/features/stock-detail/stock_detail_daily_quote_table.dart
// _DailyQuoteRow.build() 내부, 등락 컬럼

Text(
  change?.text ?? '-',
  style: style(color: change?.color ?? colors.priceFlatText),
  textAlign: TextAlign.right,
)
```

- `previous != null`이고 보합(amount == 0) → 기존처럼 `"0"` + `priceFlatText` 색상 (변경 없음, 실제 계산된 보합)
- `previous == null`(그 페이지의 가장 오래된 거래일, 계산 불가) → `"-"` + `priceFlatText` 색상

`"0"`(실제 보합)과 `"-"`(계산 불가)는 텍스트로 구분하고, 색상은 둘 다 `priceFlatText`를 사용한다
— 상승/하락이 아니라는 점에서 의미상 같은 카테고리로 취급한다.

### 3. 검색어 캡션 ellipsis 처리 (search-screen)

```dart
// lib/widgets/empty_state_view.dart
Text(
  caption,
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: ...,
)
```

`EmptyStateView`의 caption에 `maxLines: 2`(기존 caption들이 `\n`으로 2줄 구성되는 관례) +
`TextOverflow.ellipsis`를 추가해, 매우 긴 검색어가 결과없음 문구에 삽입될 때 레이아웃이
깨지지 않게 한다.

## 테스트 시나리오

### SearchResult (canonicalId 제거)

- [정상] `SearchResult`에 canonicalId 관련 필드/게터가 더 이상 존재하지 않는다 (컴파일 타임 보장)

### StockDetailDailyQuoteTable / _DailyQuoteRow

- [정상] `previous`가 null이면 일별 시세 표의 등락 컬럼은 `-`를 표시한다
- [정상] `previous`가 있고 보합(종가 동일)이면 등락 컬럼은 `0`을 표시한다 (계산 불가 `-`와 구분됨)
- [경계] `previous`가 있고 상승/하락이면 기존처럼 부호+색상이 적용된 값을 표시한다 (회귀 확인)

### EmptyStateView

- [경계] 2줄을 초과하는 매우 긴 caption이 주어지면 말줄임(...) 처리되어 렌더링된다 (overflow 없이 정상)
- [정상] 기존 caption(짧은 2줄 문구)은 그대로 온전히 표시된다 (회귀 확인)

## AC 커버리지 대조

| AC (완료 조건) | 커버 시나리오 |
| --- | --- |
| canonicalId 필드와 관련 생성 로직 제거 | "SearchResult에 canonicalId 관련 필드/게터가 더 이상 존재하지 않는다" |
| 이전 거래일 데이터가 없는 경우 "0"이 아니라 빈 값(대시)으로 표시 | "previous가 null이면 `-`를 표시한다" + "previous가 있고 보합이면 `0`을 표시한다"(구분 검증) |
| TextOverflow.ellipsis 등으로 긴 검색어 처리 | "매우 긴 caption이 말줄임 처리되어 렌더링된다" |

모든 AC가 시나리오로 커버됨.
