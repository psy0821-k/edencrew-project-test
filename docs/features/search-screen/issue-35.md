# Issue #35 — 검색 결과 행 탭 → 종목 상세 이동

## 시그니처

### `SearchResultRow`에 `onTap` 콜백 추가

```dart
class SearchResultRow extends ConsumerWidget {
  const SearchResultRow({
    super.key,
    required this.result,
    required this.query,
    required this.onToggleFavorite,
    required this.onTap,
  });

  final SearchResult result;
  final String query;
  final void Function(String symbol) onToggleFavorite;

  /// 행(별 아이콘 영역 제외) 탭 콜백. symbol만 전달한다.
  final void Function(String symbol) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

- 최상위 `Container`(padding+decoration)를 `GestureDetector`로 감싸 `onTap: () => onTap(result.symbol)` 연결.
- 별 아이콘은 이미 별도 `GestureDetector(behavior: HitTestBehavior.opaque, ...)`로 감싸져 있어, Flutter 제스처 아레나 규칙상 자식의 탭이 우선 처리되고 행 전체 탭으로 버블링되지 않는다 — 별도 처리 없이 AC2(별 아이콘 탭 시 상세 이동 발생 안 함)가 구조적으로 충족된다.

### `SearchPage`에서 연결

```dart
void _onResultTap(String symbol) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => StockDetailPage(symbol: symbol)),
  );
}
```

`SearchResultRow(..., onTap: _onResultTap)`로 전달. 기존 `StockDetailPage(symbol: ...)` 경로를 그대로 재사용(spec-fixed.md 확정 사항).

## 테스트 시나리오

### `SearchResultRow` (탭 콜백)

- [정상] 행의 텍스트/빈 영역을 탭하면 `onTap` 콜백이 해당 종목의 symbol과 함께 호출되어야 한다
- [경계] 별 아이콘 영역을 탭하면 `onTap`(행 탭)은 호출되지 않고 `onToggleFavorite`만 호출되어야 한다

### `SearchPage` (통합)

- [정상] 검색 결과 목록이 보이는 상태에서 한 행을 탭하면 해당 종목의 `StockDetailPage`로 이동해야 한다(symbol이 정확히 전달됨)
- [경계] 별 아이콘 영역을 탭하면 상세 화면으로 이동하지 않아야 한다

## AC 커버리지 대조

| GitHub #35 AC | 커버 시나리오 |
|---|---|
| 검색 결과 행 탭 → 해당 종목의 StockDetailPage로 이동(symbol 정확히 전달) | `SearchPage` [정상] 행 탭 → 상세 이동 |
| 별 아이콘 탭 시 상세 이동 발생 안 함(탭 영역 겹치지 않음) | `SearchResultRow` [경계] 별 아이콘 탭 시 onTap 미호출 + `SearchPage` [경계] 별 아이콘 탭 시 상세 이동 안 함 |
