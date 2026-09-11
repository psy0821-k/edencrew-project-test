/// 관심등록된 종목 symbol 집합을 저장·토글·조회하는 방법을 추상화합니다.
///
/// 구현체는 [LocalWatchlistRepository](SharedPreferences 기반) 하나뿐입니다.
/// Quote/Search/StockMeta 도메인과 달리 Mock/Network 이분법이 없습니다
/// (PRD ADR 1, Out of Scope).
abstract interface class WatchlistRepository {
  /// 현재 관심등록된 symbol 전체를 동기로 조회합니다.
  Set<String> getSymbols();

  /// symbol의 관심등록 상태를 토글합니다.
  ///
  /// 반환값은 토글 "이후" 상태입니다 — 등록되면 `true`, 해제되면 `false`.
  Future<bool> toggleFavorite(String symbol);

  /// 단일 symbol의 관심등록 여부를 동기로 조회합니다.
  bool isFavorite(String symbol);
}
