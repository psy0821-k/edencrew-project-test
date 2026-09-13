# Issue #33 — 관심 등록/해제: 별 아이콘 + 토스트 + 연속 클릭 방지(PendingSymbolsNotifier)

## 시그니처

### `PendingSymbolsNotifier` (`lib/shared/state/pending_symbols_notifier.dart`)

```dart
/// symbol 단위 "진행 중" 상태를 관리하는 StateNotifier.
/// 별 아이콘 토글처럼 동일 대상에 대한 중복 요청을 막는 데 쓴다.
class PendingSymbolsNotifier extends StateNotifier<Set<String>> {
  PendingSymbolsNotifier() : super(const {});

  bool isPending(String symbol);

  /// symbol이 이미 진행 중이면 아무 것도 하지 않고 반환한다.
  /// 아니면 진행 중으로 표시한 뒤 action을 실행하고, 완료(성공/실패 무관) 시 해제한다.
  Future<void> run(String symbol, Future<void> Function() action);
}

final pendingSymbolsProvider =
    StateNotifierProvider<PendingSymbolsNotifier, Set<String>>(
  (ref) => PendingSymbolsNotifier(),
);
```

### `SearchResultRow` — `StatelessWidget` → `ConsumerWidget`

```dart
class SearchResultRow extends ConsumerWidget {
  const SearchResultRow({
    super.key,
    required this.result,
    required this.query,
    required this.onToggleFavorite,
  });

  final SearchResult result;
  final String query;

  /// 별 아이콘 탭 콜백. Row는 토글 로직을 모르고 symbol만 전달한다
  /// (SearchInputField의 onChanged/onClear와 동일한 콜백 패턴).
  final void Function(String symbol) onToggleFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

- `ref.watch(isFavoriteProvider(result.symbol))`로 채워짐(`ico_star_filled.svg`)/빈(`ico_star.svg`) 별 아이콘 렌더링
- 별 아이콘은 별도 `GestureDetector`로 감싸 행 전체 탭(이슈 #35)과 영역이 겹치지 않게 구조를 미리 분리(이번 이슈는 행 전체 탭 자체는 구현하지 않음)

### `SearchPage` — 토글 트리거 + 토스트

```dart
Future<void> _onToggleFavorite(String symbol) async {
  await ref.read(pendingSymbolsProvider.notifier).run(symbol, () async {
    final isNowFavorite =
        await ref.read(watchlistProvider.notifier).toggleFavorite(symbol);
    if (!mounted) return;
    _showFavoriteToast(isNowFavorite);
  });
}

void _showFavoriteToast(bool isNowFavorite) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(isNowFavorite ? '관심이 등록되었습니다' : '관심이 해제되었습니다'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.colors.surfaceOverlay,
    ));
}
```

**판단 사항 (spec-fixed.md에 근거 기록됨)**:
- 토스트는 Figma `04`/`05` 프레임 실측 스펙이 없어 Flutter 표준 `SnackBar`(`floating`, 2초)로 구현하고 색상은 기존 `surfaceOverlay` 토큰을 재사용한다.
- "기존 토스트가 즉시 새 토스트로 교체"는 `clearSnackBars()` 후 `showSnackBar()`로 처리한다(spec-fixed.md 확정 사항).
- 노출 시간 2초의 근거는 `docs/features/search-screen/spec-fixed.md`의 "토스트 노출 시간(2초) 근거" 항목 참고.

## 테스트 시나리오

### `PendingSymbolsNotifier`

- [정상] symbol이 진행 중이 아닐 때 `run`을 호출하면 action이 실행되고 완료 후 `isPending`이 다시 `false`가 되어야 한다
- [정상] `run` 실행 중에는 해당 symbol의 `isPending`이 `true`여야 한다
- [경계] 서로 다른 symbol은 독립적으로 진행 중 상태를 가져야 한다(symbol A가 진행 중이어도 symbol B의 `run`은 정상 실행되어야 한다)
- [예외] symbol이 이미 진행 중인 상태에서 같은 symbol로 `run`을 다시 호출하면 action이 실행되지 않아야 한다
- [예외] action이 예외를 던져도 `finally`로 진행 중 상태가 해제되어야 한다(다음 `run` 호출이 가능해야 한다)

### `SearchResultRow` (별 아이콘)

- [정상] 이미 관심등록된 종목의 결과 행을 렌더링하면 채워진 별 아이콘(`ico_star_filled.svg`)이 보여야 한다
- [정상] 관심등록되지 않은 종목의 결과 행을 렌더링하면 빈 별 아이콘(`ico_star.svg`)이 보여야 한다
- [정상] 별 아이콘을 탭하면 `onToggleFavorite` 콜백이 해당 종목의 symbol과 함께 호출되어야 한다

### `SearchPage` (통합)

- [정상] 관심등록되지 않은 종목의 별 아이콘을 탭하면 즉시 채워진 별 아이콘으로 바뀌고 `관심이 등록되었습니다` 토스트가 보여야 한다
- [정상] 관심등록된 종목의 별 아이콘을 탭하면 즉시 빈 별 아이콘으로 바뀌고 `관심이 해제되었습니다` 토스트가 보여야 한다
- [경계] 토스트가 노출된 후 2초가 지나면 사라져야 한다
- [예외] 별 아이콘 토글 요청이 진행 중인 상태에서 같은 별 아이콘을 다시 탭하면 토글 요청이 중복 발생하지 않아야 한다
- [경계] A 종목 등록 토스트가 떠 있는 상태에서 B 종목의 별 아이콘을 탭해 해제 토스트가 발생하면 기존 토스트가 즉시 새 토스트로 교체되어야 한다

## AC 커버리지 대조

| GitHub #33 AC | 커버 시나리오 |
|---|---|
| 이미 관심등록된 종목 → 별 아이콘 채워진 상태로 렌더링 | `SearchResultRow` [정상] 이미 관심등록된 종목 |
| 빈 별 아이콘 탭 → 즉시 채워짐 + 등록 토스트(2초 후 소멸) | `SearchPage` [정상] 등록 토스트 + [경계] 2초 후 소멸 |
| 채워진 별 아이콘 탭 → 즉시 빈 별로 + 해제 토스트 | `SearchPage` [정상] 해제 토스트 |
| 진행 중 상태에서 재탭 → 중복 무시 | `PendingSymbolsNotifier` [예외] 중복 호출 무시 + `SearchPage` [예외] 통합 검증 |
| A 등록 토스트 중 B 해제 토스트 → 즉시 교체 | `SearchPage` [경계] 토스트 교체 |
