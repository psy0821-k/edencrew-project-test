import 'package:edencrew_assignment_starter/entities/quote/quote.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/quote/quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_providers.dart';
import 'package:edencrew_assignment_starter/entities/stock_meta/stock_meta_repository.dart';
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
  Future<bool> toggleFavorite(String symbol) async {
    if (_symbols.contains(symbol)) {
      _symbols.remove(symbol);
      return false;
    }
    _symbols.add(symbol);
    return true;
  }
}

StockMeta _stockMetaFor(String symbol) =>
    StockMeta(symbol: symbol, name: '종목-$symbol', marketName: '코스피');

Quote _quoteFor(String symbol) => Quote(
  symbol: symbol,
  currentPrice: 70000,
  previousClose: 69000,
  open: 69500,
  high: 70500,
  low: 69000,
  volume: 1000000,
  countOfListedStock: 100,
);

class _FakeStockMetaRepository implements StockMetaRepository {
  _FakeStockMetaRepository({List<String>? failFor})
    : _failFor = failFor ?? const [];

  final List<String> _failFor;
  final List<String> fetchedSymbols = [];

  @override
  Future<StockMeta> fetchStockMeta(String symbol) async {
    fetchedSymbols.add(symbol);
    if (_failFor.contains(symbol)) {
      throw Exception('StockMeta fetch failed for $symbol');
    }
    return _stockMetaFor(symbol);
  }
}

class _FakeQuoteRepository implements QuoteRepository {
  _FakeQuoteRepository({Set<String>? missingSymbols})
    : _missingSymbols = missingSymbols ?? {};

  final Set<String> _missingSymbols;
  final List<List<String>> fetchCalls = [];

  @override
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    fetchCalls.add(symbols);
    return {
      for (final symbol in symbols)
        if (!_missingSymbols.contains(symbol)) symbol: _quoteFor(symbol),
    };
  }
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

  group('watchlistItemsProvider', () {
    test(
      'should return WatchlistItem list combining StockMeta and Quote per symbol when two symbols are watched and both quotes succeed',
      () async {
        final watchlistRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930', '000660'},
        );
        final quoteRepository = _FakeQuoteRepository();
        final stockMetaRepository = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              watchlistRepository,
            ),
            quoteRepositoryProvider.overrideWithValue(quoteRepository),
            stockMetaRepositoryProvider.overrideWithValue(
              stockMetaRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final items = await container.read(watchlistItemsProvider.future);

        expect(items, hasLength(2));
        final symbols = items.map((item) => item.symbol).toSet();
        expect(symbols, {'005930', '000660'});
        for (final item in items) {
          expect(item.stockMeta.symbol, item.symbol);
          expect(item.quote, isNotNull);
          expect(item.quote!.symbol, item.symbol);
        }
      },
    );

    test(
      'should call fetchQuotes once with all symbols instead of calling it per symbol when two symbols are watched',
      () async {
        final watchlistRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930', '000660'},
        );
        final quoteRepository = _FakeQuoteRepository();
        final stockMetaRepository = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              watchlistRepository,
            ),
            quoteRepositoryProvider.overrideWithValue(quoteRepository),
            stockMetaRepositoryProvider.overrideWithValue(
              stockMetaRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(watchlistItemsProvider.future);

        expect(quoteRepository.fetchCalls, hasLength(1));
        expect(
          quoteRepository.fetchCalls.single.toSet(),
          {'005930', '000660'},
        );
      },
    );

    test(
      'should return an empty list without calling fetchQuotes/fetchStockMeta when no symbol is watched',
      () async {
        final watchlistRepository = _FakeWatchlistRepository();
        final quoteRepository = _FakeQuoteRepository();
        final stockMetaRepository = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              watchlistRepository,
            ),
            quoteRepositoryProvider.overrideWithValue(quoteRepository),
            stockMetaRepositoryProvider.overrideWithValue(
              stockMetaRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final items = await container.read(watchlistItemsProvider.future);

        expect(items, isEmpty);
        expect(quoteRepository.fetchCalls, isEmpty);
        expect(stockMetaRepository.fetchedSymbols, isEmpty);
      },
    );

    test(
      'should return a list containing one WatchlistItem when one symbol is watched',
      () async {
        final watchlistRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930'},
        );
        final quoteRepository = _FakeQuoteRepository();
        final stockMetaRepository = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              watchlistRepository,
            ),
            quoteRepositoryProvider.overrideWithValue(quoteRepository),
            stockMetaRepositoryProvider.overrideWithValue(
              stockMetaRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final items = await container.read(watchlistItemsProvider.future);

        expect(items, hasLength(1));
        expect(items.single.symbol, '005930');
      },
    );

    test(
      'should have a null quote for the missing symbol while the rest remain normal (non-null quote) when a specific symbol is missing from the fetchQuotes response',
      () async {
        final watchlistRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930', '000660'},
        );
        final quoteRepository = _FakeQuoteRepository(
          missingSymbols: {'000660'},
        );
        final stockMetaRepository = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              watchlistRepository,
            ),
            quoteRepositoryProvider.overrideWithValue(quoteRepository),
            stockMetaRepositoryProvider.overrideWithValue(
              stockMetaRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final items = await container.read(watchlistItemsProvider.future);

        final missingItem = items.firstWhere(
          (item) => item.symbol == '000660',
        );
        final normalItem = items.firstWhere(
          (item) => item.symbol == '005930',
        );
        expect(missingItem.quote, isNull);
        expect(normalItem.quote, isNotNull);
      },
    );

    test(
      'should have all WatchlistItem.quote null with list length equal to the symbol count when every watched symbol is missing from the fetchQuotes response',
      () async {
        final watchlistRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930', '000660'},
        );
        final quoteRepository = _FakeQuoteRepository(
          missingSymbols: {'005930', '000660'},
        );
        final stockMetaRepository = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              watchlistRepository,
            ),
            quoteRepositoryProvider.overrideWithValue(quoteRepository),
            stockMetaRepositoryProvider.overrideWithValue(
              stockMetaRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final items = await container.read(watchlistItemsProvider.future);

        expect(items, hasLength(2));
        expect(items.every((item) => item.quote == null), isTrue);
      },
    );

    test(
      'should automatically recompute and reflect the changed symbol set when watchlistProvider symbol set changes (e.g. via toggleFavorite)',
      () async {
        final watchlistRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930'},
        );
        final quoteRepository = _FakeQuoteRepository();
        final stockMetaRepository = _FakeStockMetaRepository();
        final container = ProviderContainer(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(
              watchlistRepository,
            ),
            quoteRepositoryProvider.overrideWithValue(quoteRepository),
            stockMetaRepositoryProvider.overrideWithValue(
              stockMetaRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final initialItems = await container.read(
          watchlistItemsProvider.future,
        );
        expect(initialItems.map((item) => item.symbol).toSet(), {'005930'});

        await container.read(watchlistProvider.notifier).toggleFavorite(
          '000660',
        );

        final updatedItems = await container.read(
          watchlistItemsProvider.future,
        );
        expect(
          updatedItems.map((item) => item.symbol).toSet(),
          {'005930', '000660'},
        );
      },
    );
  });

  group('isFavoriteProvider', () {
    test(
      'should return true when subscribing to isFavoriteProvider("005930") while "005930" is watched',
      () {
        final fake = _FakeWatchlistRepository(initialSymbols: {'005930'});
        final container = ProviderContainer(
          overrides: [watchlistRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final result = container.read(isFavoriteProvider('005930'));

        expect(result, isTrue);
      },
    );

    test(
      'should return false when subscribing to isFavoriteProvider for a symbol that is not watched',
      () {
        final fake = _FakeWatchlistRepository(initialSymbols: {'005930'});
        final container = ProviderContainer(
          overrides: [watchlistRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final result = container.read(isFavoriteProvider('000660'));

        expect(result, isFalse);
      },
    );

    test(
      'should automatically update to false without resubscribing when toggleFavorite("005930") unwatches it while subscribed to isFavoriteProvider("005930")',
      () async {
        final fake = _FakeWatchlistRepository(initialSymbols: {'005930'});
        final container = ProviderContainer(
          overrides: [watchlistRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          isFavoriteProvider('005930'),
          (previous, next) {},
        );
        expect(sub.read(), isTrue);

        await container
            .read(watchlistProvider.notifier)
            .toggleFavorite('005930');

        expect(sub.read(), isFalse);
      },
    );

    test(
      'should automatically update to true when toggleFavorite("005930") watches it while subscribed to isFavoriteProvider("005930")',
      () async {
        final fake = _FakeWatchlistRepository();
        final container = ProviderContainer(
          overrides: [watchlistRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          isFavoriteProvider('005930'),
          (previous, next) {},
        );
        expect(sub.read(), isFalse);

        await container
            .read(watchlistProvider.notifier)
            .toggleFavorite('005930');

        expect(sub.read(), isTrue);
      },
    );
  });
}
