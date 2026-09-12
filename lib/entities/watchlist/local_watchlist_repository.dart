import 'package:shared_preferences/shared_preferences.dart';

import 'watchlist_repository.dart';

/// SharedPreferences로 관심종목 symbol 집합을 영속화하는 구현체.
///
/// 생성자는 이미 로드가 끝난 [SharedPreferences] 인스턴스를 주입받습니다
/// (`main()`에서 `await SharedPreferences.getInstance()`로 사전 로드 —
/// PRD ADR 1의 "완전히 동기 인터페이스" 전제).
class LocalWatchlistRepository implements WatchlistRepository {
  LocalWatchlistRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _watchlistSymbolsKey = 'watchlist_symbols';

  @override
  Set<String> getSymbols() {
    final stored = _preferences.getStringList(_watchlistSymbolsKey);
    return stored == null ? {} : stored.toSet();
  }

  @override
  Future<bool> toggleFavorite(String symbol) async {
    final symbols = getSymbols();
    final nowFavorite = !symbols.contains(symbol);

    if (nowFavorite) {
      symbols.add(symbol);
    } else {
      symbols.remove(symbol);
    }

    await _preferences.setStringList(_watchlistSymbolsKey, symbols.toList());
    return nowFavorite;
  }

  @override
  bool isFavorite(String symbol) => getSymbols().contains(symbol);
}
