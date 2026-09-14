# Issue #58 — 캔들 차트

## 시그니처

```dart
// lib/features/stock-detail/stock_detail_candle_chart.dart (신규)

/// 캔들 차트. `quotes`는 [StockDetailDailyQuoteTable]과 동일하게 최신순으로
/// 들어오므로, 위젯 내부에서 날짜 오름차순으로 반전해 왼쪽부터 과거 → 오른쪽 최신
/// 순으로 그린다. 기간 탭 전환 시 `quotes`가 바뀌면 자동으로 다시 그려진다
/// (별도 배선 불필요 — StockDetailPage가 이미 stale-while-revalidate로 관리).
class StockDetailCandleChart extends StatelessWidget {
  const StockDetailCandleChart({super.key, required this.quotes});

  final List<DailyQuote> quotes;

  @override
  Widget build(BuildContext context);
}

/// 캔들 렌더링을 담당하는 CustomPainter.
class _CandleChartPainter extends CustomPainter {
  const _CandleChartPainter({
    required this.quotes,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
  });

  /// 날짜 오름차순(과거 → 최신)으로 정렬된 목록.
  final List<DailyQuote> quotes;
  final Color upColor;
  final Color downColor;
  final Color flatColor;

  @override
  void paint(Canvas canvas, Size size);

  @override
  bool shouldRepaint(covariant _CandleChartPainter oldDelegate);
}
```

### 색상 규칙

- `closePrice > openPrice` → `upColor` (`context.colors.chartLineUp`, 상승/빨강)
- `closePrice < openPrice` → `downColor` (`context.colors.chartLineDown`, 하락/파랑)
- `closePrice == openPrice` → `flatColor` (`context.colors.chartLineFlat`, 보합)

### 예외 처리

- `quotes`가 빈 리스트면 아무 것도 그리지 않는다(빈 Canvas). `StockDetailPage`는 `dailyQuotes == null`일 때 이미 스켈레톤으로 분기하므로, 이 위젯은 "값은 있으나 빈 리스트"인 방어적 케이스만 담당한다.

### 페이지 연동

`StockDetailPage._buildBody`의 `dailyQuotes != null` 분기에서 `StockDetailSummaryCard`와 `StockDetailDailyQuoteTable` 사이에 `StockDetailCandleChart(quotes: dailyQuotes)`를 추가한다. `dailyQuotes`는 기간 탭 전환 시 이미 갱신되는 값이므로 차트도 표/카드와 함께 자동으로 교체된다.

### 디자인 (내일 조정 예정 — 오늘은 최소 기준만)

- 차트 높이 등 세부 수치는 임시 상수로 처리하고, 시안 맞춤은 다음 세션에서 진행한다.

## 테스트 시나리오

### StockDetailCandleChart / _CandleChartPainter

- [정상] `quotes`에 N개의 일별 시세가 있으면, 캔들이 N개 그려진다 (paint 호출 시 `quotes.length`만큼 캔들 도형이 생성됨을 검증)
- [정상] 특정 거래일의 `closePrice > openPrice`이면, 그 캔들이 `chartLineUp` 색상으로 그려진다
- [정상] 특정 거래일의 `closePrice < openPrice`이면, 그 캔들이 `chartLineDown` 색상으로 그려진다
- [경계] 특정 거래일의 `closePrice == openPrice`이면, 그 캔들이 `chartLineFlat` 색상으로 그려진다
- [경계] `quotes`가 최신순(내림차순)으로 입력되어도, 캔들은 날짜 오름차순(과거 → 최신)으로 배치되어 그려진다
- [예외] `quotes`가 빈 리스트이면, 캔들을 그리지 않고 예외 없이 렌더링된다
- [정상] `shouldRepaint`는 `quotes` 내용이 바뀌면 true를 반환한다 (기간 탭 전환 시 재도색 보장)

### StockDetailPage 연동

- [정상] 기간 탭을 전환해 `dailyQuotes`가 새 기간 데이터로 교체되면, 캔들 차트도 표/카드와 함께 새 데이터로 교체된다

## AC 커버리지 대조

| AC | 커버 시나리오 |
| --- | --- |
| `1개월` 데이터가 로드되면 그 기간의 거래일 수만큼 캔들이 그려진다 | "quotes에 N개의 일별 시세가 있으면 캔들이 N개 그려진다" |
| 종가 > 시가 → `chartLineUp` 색상 | "closePrice > openPrice이면 chartLineUp 색상" |
| 종가 < 시가 → `chartLineDown` 색상 | "closePrice < openPrice이면 chartLineDown 색상" |
| 기간 탭 전환 시 캔들 차트도 표/카드와 함께 새 기간 데이터로 교체 | "기간 탭을 전환해 dailyQuotes가 새 기간 데이터로 교체되면 캔들 차트도 함께 교체된다" + "shouldRepaint는 quotes 내용이 바뀌면 true" |

모든 AC가 시나리오로 커버됨.
