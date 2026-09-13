import 'package:flutter_riverpod/flutter_riverpod.dart';

/// symbol 단위 "진행 중" 상태를 관리하는 StateNotifier.
/// 별 아이콘 토글처럼 동일 대상에 대한 중복 요청을 막는 데 쓴다.
class PendingSymbolsNotifier extends StateNotifier<Set<String>> {
  PendingSymbolsNotifier() : super(const {});

  bool isPending(String symbol) => state.contains(symbol);

  /// symbol이 이미 진행 중이면 아무 것도 하지 않고 반환한다.
  /// 아니면 진행 중으로 표시한 뒤 action을 실행하고, 완료(성공/실패 무관) 시 해제한다.
  Future<void> run(String symbol, Future<void> Function() action) async {
    if (isPending(symbol)) return;
    state = {...state, symbol};
    try {
      await action();
    } finally {
      state = {...state}..remove(symbol);
    }
  }
}

final pendingSymbolsProvider =
    StateNotifierProvider<PendingSymbolsNotifier, Set<String>>(
  (ref) => PendingSymbolsNotifier(),
);
