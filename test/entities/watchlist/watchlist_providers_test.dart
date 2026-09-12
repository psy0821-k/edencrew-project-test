import 'package:edencrew_assignment_starter/entities/watchlist/local_watchlist_repository.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({Set<String>? initialSymbols})
    : _symbols = initialSymbols ?? {};

  final Set<String> _symbols;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async => false;
}

void main() {
  group('sharedPreferencesProvider', () {
    test(
      'should throw when sharedPreferencesProvider is read without override',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(sharedPreferencesProvider),
          throwsUnimplementedError,
        );
      },
    );
  });

  group('watchlistRepositoryProvider', () {
    test(
      'should build LocalWatchlistRepository from overridden SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final repository = container.read(watchlistRepositoryProvider);

        expect(repository, isA<LocalWatchlistRepository>());
      },
    );

    test(
      'should allow overriding watchlistRepositoryProvider directly with a fake',
      () {
        final fake = _FakeWatchlistRepository();
        final container = ProviderContainer(
          overrides: [watchlistRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final repository = container.read(watchlistRepositoryProvider);

        expect(repository, same(fake));
      },
    );
  });

  group('watchlistProvider', () {
    test(
      'should expose watchlistProvider as a StateNotifierProvider synced with the repository',
      () {
        final fake = _FakeWatchlistRepository(initialSymbols: {'005930'});
        final container = ProviderContainer(
          overrides: [watchlistRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final state = container.read(watchlistProvider);

        expect(state, {'005930'});
      },
    );
  });
}
