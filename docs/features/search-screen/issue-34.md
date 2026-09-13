# Issue #34 — 관심 화면 새로고침 버튼에 연속 클릭 방지(PendingFlagNotifier) 적용

## 시그니처

```dart
/// bool 단위 "진행 중" 상태를 관리하는 StateNotifier.
/// 새로고침 버튼처럼 동일 액션의 중복 실행을 막는 데 쓴다.
/// PendingSymbolsNotifier와 같은 뼈대(진행 중 표시 → action 실행 → 완료 시 해제)를 공유한다.
class PendingFlagNotifier extends StateNotifier<bool> {
  PendingFlagNotifier() : super(false);

  bool get isPending => state;

  /// 이미 진행 중이면 아무 것도 하지 않고 반환한다.
  /// 아니면 진행 중으로 표시한 뒤 action을 실행하고, 완료(성공/실패 무관) 시 해제한다.
  Future<void> run(Future<void> Function() action) async {
    if (isPending) return;
    state = true;
    try {
      await action();
    } finally {
      state = false;
    }
  }
}

final watchlistRefreshPendingProvider =
    StateNotifierProvider<PendingFlagNotifier, bool>(
  (ref) => PendingFlagNotifier(),
);
```

- 위치: `lib/shared/state/pending_flag_notifier.dart` (신규)
- `WatchlistPage`: `onRefreshTap`을 `ref.read(watchlistRefreshPendingProvider.notifier).run(...)`으로 감싸고, action 내부에서 `ref.invalidate(watchlistItemsProvider)` 후 `ref.read(watchlistItemsProvider.future)`로 재조회 완료를 기다린다(invalidate 자체는 동기이므로 future를 await해야 "진행 중" 판단이 의미 있음).

## 테스트 시나리오

### PendingFlagNotifier

- [정상] `run`을 호출하면 action이 실행되고, 완료 후 진행 중 상태가 해제된다
- [정상] 진행 중인 상태에서 `run`을 다시 호출하면 action이 실행되지 않는다
- [예외] action이 예외를 던지면 그 예외가 호출자에게 전파되고, 진행 중 상태는 해제된다(성공/실패 무관 해제)

### WatchlistPage

- [정상] 새로고침 버튼을 연속으로 빠르게 탭하면 `watchlistItemsProvider` 재조회가 한 번만 트리거된다
