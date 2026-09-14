# Issue #73 — 종목상세 페이지 진입 시 로딩 스피너 적용

## 시그니처 (v2 — 스피너 종료 조건 확장)

최초 논의(v1)에서는 quote/stockMeta 로딩만 스피너로 가렸으나, 그 직후 dailyQuotes(차트/표
데이터)가 아직 없어 본문 안에 다시 SkeletonBox가 나타나는 문제가 있었다. 사용자 요청에 따라
"스피너 시작 → 차트/일별시세 렌더링 완료 → 스피너 종료"로 조건을 확장한다. 요약카드는
캔들차트/일별시세표와 같은 `dailyQuotes` 소스를 쓰므로 스피너가 걷히는 시점엔 이미 데이터가
준비되어 있다.

영역별(차트/요약카드/표) 스켈레톤 모양 개선은 검토했으나, 기간 탭 전환 시 기존
stale-while-revalidate 동작(이전 데이터 유지) 때문에 실제로 노출될 시나리오가 없어 이번
이슈 범위에서 보류한다.

```dart
// lib/pages/stock_detail_page.dart

Widget build(BuildContext context, WidgetRef ref) {
  final quote = ref.watch(quoteProvider(symbol));
  final stockMeta = ref.watch(stockMetaProvider(symbol));
  final dailyQuoteState = ref.watch(stockDetailDailyQuoteProvider(symbol));
  // _buildBody에 dailyQuoteState 전달
}

Widget _buildBody(
  ...,
  StockDetailDailyQuoteState dailyQuoteState,
) {
  if (quote.hasError || stockMeta.hasError) { ... }  // 기존 유지

  final isInitialLoading =
      !quote.hasValue || !stockMeta.hasValue || dailyQuoteState.quotes == null;
  if (isInitialLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  final dailyQuotes = dailyQuoteState.quotes!;
  // "if (dailyQuotes == null) SkeletonBox" 분기는 스피너 단계에서 이미 걸러지므로 제거
  // 캔들차트/요약카드/표는 항상 dailyQuotes로 렌더링
}
```

- 스피너 종료 조건에 `dailyQuoteState.quotes == null` 추가.
- 본문 내부의 `if (dailyQuotes == null) SkeletonBox` 분기 제거(도달 불가 코드가 됨).
- `_bodySkeletonHeight` 상수와 `SkeletonBox` import는 더 쓰이지 않으면 제거.
- 기간 탭 전환은 `StockDetailDailyQuoteNotifier`의 `_lastQuotes`(stale-while-revalidate)
  덕분에 `quotes`가 `null`이 되지 않으므로, 스피너와 기존 "탭 전환 중 표/카드 유지" 동작
  모두 영향받지 않는다.

## 테스트 시나리오

### StockDetailPage

- [정상] quote/stockMeta/dailyQuotes 중 하나라도 아직 없으면 본문 영역에
  `CircularProgressIndicator`가 표시된다
- [정상] 로딩 중에도 헤더(뒤로가기 버튼)는 계속 표시된다
- [정상] 셋 다 준비되면 스피너가 사라지고 헤더+가격+기간탭+캔들차트+요약카드+표가 한 번에
  나타난다
- [경계] 기간 탭을 전환해도(재조회 중) 스피너가 다시 나타나지 않고 기존 표/카드가 그대로
  유지된다 (stale-while-revalidate 회귀 확인)

## 시그니처 (v3 — 시안 세부 스타일 보정)

이슈 범위를 벗어나지만 같은 화면 작업 중 발견된 시안 불일치를 함께 보정한다.

### 헤더 하단 보더

```dart
// lib/features/stock-detail/stock_detail_header.dart
return Container(
  constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
  padding: EdgeInsets.symmetric(horizontal: dimens.space2),
  decoration: BoxDecoration(
    border: Border(
      bottom: BorderSide(
        width: dimens.borderHairline,
        color: colors.borderSubtle,
      ),
    ),
  ),
  child: Row(...),
);
```

### 본문 패딩

```dart
// lib/pages/stock_detail_page.dart
return SingleChildScrollView(
  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
  child: Column(...),
);
```

기간탭↔차트, 요약카드↔표 사이 gap(16px/24px)은 이미 v2에서 반영됨. "간격 24px"로
언급된 추가 항목은 의미가 불명확해 이번 작업 범위에서 보류.

### 테스트 시나리오 추가

- [정상] `StockDetailHeader`는 하단에 `borderSubtle` 색상의 1px 보더를 가진다
- [정상] 상세 페이지 본문의 padding은 top 14 / right 16 / bottom 16 / left 16이다

## AC 커버리지 대조

| AC (완료 조건) | 커버 시나리오 |
| --- | --- |
| 헤더는 로딩 중에도 항상 표시 | "로딩 중에도 헤더(뒤로가기 버튼)는 계속 표시된다" |
| 본문만 로딩 중일 때 스피너로 대체 | "quote/stockMeta/dailyQuotes 중 하나라도 아직 없으면 본문 영역에 CircularProgressIndicator가 표시된다" |
| 차트+일별시세 렌더링 완료 후 스피너 종료 | "셋 다 준비되면 스피너가 사라지고 헤더+가격+기간탭+캔들차트+요약카드+표가 한 번에 나타난다" |
| 기간 탭 전환은 스피너 영향 없음 | "기간 탭을 전환해도 스피너가 다시 나타나지 않고 기존 표/카드가 그대로 유지된다" |

모든 AC가 시나리오로 커버됨.
