# Issue #30 — 공용 EmptyStateView 추출 + WatchlistEmptyView 재구성

## 시그니처

```dart
// lib/widgets/empty_state_view.dart
/// 아이콘 + 타이틀 + 캡션으로 구성된 공용 빈/안내 상태 뷰.
/// 관심 화면의 빈 상태, 검색 화면의 초기/결과없음 상태가 이 위에서 구성된다.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.caption,
  });

  /// 표시할 SVG 아이콘 asset 경로. 예: `assets/icons/ico_star.svg`
  final String iconAsset;

  /// 굵게 표시되는 제목 문구. 예: `관심 종목이 없습니다`
  final String title;

  /// 제목 아래 보조 설명 문구. 예: `검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.`
  final String caption;

  @override
  Widget build(BuildContext context) { ... }
}
```

```dart
// lib/features/watchlist-list/watchlist_empty_view.dart (재구성)
/// 관심종목이 하나도 없을 때 보여주는 빈 상태 뷰. (`01 · 관심_empty`)
/// EmptyStateView를 관심 화면 문구로 고정해 호출하는 얇은 래퍼.
class WatchlistEmptyView extends StatelessWidget {
  const WatchlistEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateView(
      iconAsset: 'assets/icons/ico_star.svg',
      title: '관심 종목이 없습니다',
      caption: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
    );
  }
}
```

레이아웃 상수(아이콘 크기 48, 타이틀 폰트 19/행간 22/자간 -0.2, 캡션 폰트 11/행간 14, gap 16)는 기존
`WatchlistEmptyView`에 있던 값을 그대로 `EmptyStateView` 내부로 이동한다. 새로 값을 정하지 않는다.

> 참고: 검색 화면(이슈 2)에서는 `EmptyStateView(iconAsset: 'assets/icons/ico_search.svg', ...)`로 호출한다.
> 이번 이슈는 `EmptyStateView` 자체와 `WatchlistEmptyView` 재구성만 다루며, 검색 화면 호출부는 범위 밖이다.

## 테스트 시나리오

### EmptyStateView

- [정상] iconAsset/title/caption을 전달하면 각각 SvgPicture(해당 asset 경로)와 Text(title), Text(caption)로 화면에 그대로 렌더링해야 한다
- [정상] 관심 화면 문구가 아닌 임의의 title/caption을 전달해도 넘긴 값 그대로 표시해야 한다 (범용성 검증)
- [경계] caption에 개행(`\n`)이 포함된 문자열을 전달하면 개행이 유지된 채로 렌더링해야 한다

### WatchlistEmptyView

- [정상] 렌더링하면 `ico_star.svg` 아이콘, `관심 종목이 없습니다` 타이틀, `검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.` 캡션을 보여줘야 한다 (기존 동작과 동일 — 시각적 회귀 없음)

### WatchlistPage (회귀 확인)

- [정상] 관심종목이 0개인 상태로 렌더링하면 기존과 동일하게 빈 상태 화면(WatchlistEmptyView 경유 EmptyStateView)을 보여줘야 한다

## AC 커버리지

| AC | 커버 시나리오 |
|---|---|
| 관심 화면 빈 상태 시각적 회귀 없음 | WatchlistEmptyView 정상 시나리오, WatchlistPage 회귀 시나리오 |
| EmptyStateView 범용성(다른 값 전달 시 그대로 표시) | EmptyStateView 정상 시나리오 2건 |
| 기존 관심 화면 위젯 테스트 회귀 없음 | tdd-green 단계에서 `flutter test` 전체 실행으로 확인 (신규 시나리오 불필요) |
