# Issue #73 — 종목상세 페이지 진입 시 로딩 스피너 적용

## 시그니처

```dart
// lib/pages/stock_detail_page.dart, _buildBody() 내부

// 변경 전: quote/stockMeta 최초 로딩 중 SkeletonBox
if (!quote.hasValue || !stockMeta.hasValue) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: dimens.space4),
    child: const SkeletonBox(width: double.infinity, height: _bodySkeletonHeight),
  );
}

// 변경 후: CircularProgressIndicator
if (!quote.hasValue || !stockMeta.hasValue) {
  return const Center(child: CircularProgressIndicator());
}
```

- 헤더(`StockDetailHeader`)는 `build()`에서 항상 렌더링되므로 이 변경과 무관하게 유지됨.
- 기간 탭 전환 시 `dailyQuotes == null` 분기(일별 시세 재로딩)는 변경하지 않는다 — 기존
  `SkeletonBox` 그대로 유지.

## 테스트 시나리오

### StockDetailPage

- [정상] quote/stockMeta가 아직 도착하지 않으면 본문 영역에 `CircularProgressIndicator`가
  표시된다
- [정상] 로딩 중에도 헤더(뒤로가기 버튼)는 계속 표시된다
- [정상] 로딩이 완료되면 스피너가 사라지고 실제 화면(현재가 등)이 표시된다
- [경계] 기간 탭 전환 중(dailyQuotes 재로딩)에는 여전히 `SkeletonBox`가 표시된다
  (`CircularProgressIndicator`가 아님, 회귀 확인)

## AC 커버리지 대조

| AC (완료 조건) | 커버 시나리오 |
| --- | --- |
| 헤더는 로딩 중에도 항상 표시 | "로딩 중에도 헤더(뒤로가기 버튼)는 계속 표시된다" |
| 본문만 로딩 중일 때 스피너로 대체 | "quote/stockMeta가 아직 도착하지 않으면 본문 영역에 CircularProgressIndicator가 표시된다" + "로딩이 완료되면 스피너가 사라지고 실제 화면이 표시된다" |
| 기간 탭 전환 로딩은 대상 아님 | "기간 탭 전환 중에는 여전히 SkeletonBox가 표시된다" |

모든 AC가 시나리오로 커버됨.
