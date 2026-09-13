# Issue #61 — 관심 화면 종목 행 탭 → 종목 상세 이동 + 관심 해제(close) 버튼

## 시그니처

```dart
// lib/features/watchlist-list/watchlist_row.dart (수정)
/// 관심 화면의 종목 행 하나. (`01 · 관심`의 일반 행)
/// 행을 탭하면 상세 화면으로 이동하고, close 아이콘을 탭하면 관심을 해제한다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRemoveTap,
  });

  final WatchlistItem item;

  /// 행(close 아이콘 영역 제외) 탭 콜백. symbol만 전달한다.
  final void Function(String symbol) onTap;

  /// close 아이콘 탭 콜백. symbol만 전달한다. Row는 해제 로직을 모른다.
  final void Function(String symbol) onRemoveTap;

  @override
  Widget build(BuildContext context) { ... }
}
```

```dart
// lib/pages/watchlist_page.dart (수정)
class WatchlistPage extends ConsumerWidget {
  void _onRowTap(BuildContext context, String symbol) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StockDetailPage(symbol: symbol)),
    );
  }

  Future<void> _onRemoveTap(BuildContext context, WidgetRef ref, String symbol) async {
    await ref.read(pendingSymbolsProvider.notifier).run(symbol, () async {
      final isNowFavorite = await ref.read(watchlistProvider.notifier).toggleFavorite(symbol);
      if (!context.mounted) return;
      showFavoriteToast(context, isNowFavorite);
    });
  }
}
```

### 동작 방식

- `WatchlistRow`는 `GestureDetector(onTap: () => onTap(item.symbol))`로 행 전체를 감싸고, close 아이콘만 별도 `GestureDetector`(`HitTestBehavior.opaque`)로 감싸 `onRemoveTap`을 호출한다 — `SearchResultRow`의 별 아이콘/행 탭 분리 패턴과 동일.
- close 아이콘은 `assets/icons/ico_close.svg` 신규 추가, `context.colors.textTertiary` 사용.
- `_onRemoveTap`은 `pendingSymbolsProvider`로 연속 클릭 방지 + 기존 `showFavoriteToast` 재사용(관심 화면은 탭바가 있는 화면이므로 `showTabBarGap` 기본값 `true` 그대로 사용).
- 관심 해제 즉시 `watchlistProvider`(Set) 갱신 → `watchlistItemsProvider`가 재계산되어 `WatchlistRow`가 목록에서 자동으로 사라진다(별도 로컬 상태 불필요).
- 확인 다이얼로그 없음(즉시 해제, 토스증권 스타일).

## 테스트 시나리오

### WatchlistRow

- [정상] 행(close 아이콘 영역 제외)을 탭하면 `onTap`이 symbol과 함께 호출된다
- [정상] close 아이콘을 탭하면 `onRemoveTap`이 symbol과 함께 호출된다
- [정상] close 아이콘을 탭해도 `onTap`은 호출되지 않는다(탭 영역이 겹치지 않음)
- [정상] close 아이콘이 표시된다(`assets/icons/ico_close.svg`)

### WatchlistPage (통합)

- [정상] 관심 화면에서 종목 행을 탭하면 `StockDetailPage(symbol: ...)`로 이동한다 (symbol이 정확히 전달됨)
- [정상] 상세 화면 진입 후 뒤로가기를 누르면 관심 화면으로 돌아오고, 목록 상태(정렬/관심 여부)가 유지된다
- [정상] close 아이콘을 탭하면 확인 절차 없이 즉시 관심이 해제되고 목록에서 사라지며 토스트("관심이 해제되었습니다")가 표시된다
- [경계] close 아이콘을 연속으로 빠르게 탭하면 두 번째 탭은 무시된다(`PendingSymbolsNotifier`)

모든 시나리오는 `test/features/watchlist-list/watchlist_row_test.dart`, `test/pages/watchlist_page_test.dart`에 구현·통과 확인됨.

## AC 커버리지

| AC | 커버하는 시나리오 |
|---|---|
| 종목 행 탭 → 상세 이동(symbol 정확히 전달) | WatchlistPage 통합 1번 |
| 뒤로가기 시 목록 상태(정렬/관심 여부) 유지 | WatchlistPage 통합 2번 |
| close 아이콘 탭 → 즉시 해제 + 목록에서 제거 + 토스트 | WatchlistPage 통합 3번 |
| close 아이콘 탭 시 상세 이동 발생하지 않음(탭 영역 분리) | WatchlistRow 3번 |
| close 아이콘 연속 탭 시 두 번째 무시 | WatchlistPage 통합 4번 |
