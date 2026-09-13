import 'package:flutter_riverpod/flutter_riverpod.dart';

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
