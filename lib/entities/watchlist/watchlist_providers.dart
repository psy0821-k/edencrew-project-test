import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_watchlist_repository.dart';
import 'watchlist_notifier.dart';
import 'watchlist_repository.dart';

/// main()에서 overrideWithValue로 주입되는 것을 전제합니다.
/// 기본 구현이 없으므로 override 없이 read하면 예외를 던집니다.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider는 main()에서 overrideWithValue로 주입되어야 합니다.',
  );
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return LocalWatchlistRepository(ref.watch(sharedPreferencesProvider));
});

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, Set<String>>((ref) {
  return WatchlistNotifier(ref.watch(watchlistRepositoryProvider));
});
