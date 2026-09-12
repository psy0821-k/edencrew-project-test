import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'watchlist_repository.dart';

/// 관심종목 symbol 집합의 메모리 상태를 들고 있는 StateNotifier.
///
/// 생성 시 Repository의 `getSymbols()`로 초기 state를 동기 설정합니다
/// (SharedPreferences가 이미 로드된 상태라는 전제 — main.dart 배선은 별도 이슈).
class WatchlistNotifier extends StateNotifier<Set<String>> {
  WatchlistNotifier(this._repository) : super(_repository.getSymbols());

  final WatchlistRepository _repository;

  /// Repository에 토글을 위임한 뒤 state를 갱신하고, 토글 결과를 그대로 반환합니다.
  Future<bool> toggleFavorite(String symbol) async {
    final result = await _repository.toggleFavorite(symbol);
    // Repository 구현이 getSymbols()에서 동일 Set 참조를 반환하더라도
    // (in-place 변경) 새 인스턴스를 대입해 리스너에게 변경을 알린다.
    state = Set.of(_repository.getSymbols());
    return result;
  }
}
