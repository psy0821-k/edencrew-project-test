import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_notifier.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({
    Set<String>? initialSymbols,
    bool? toggleResult,
    Set<String>? symbolsAfterToggle,
  }) : _symbols = initialSymbols ?? {},
       _toggleResult = toggleResult,
       _symbolsAfterToggle = symbolsAfterToggle;

  Set<String> _symbols;
  final bool? _toggleResult;
  final Set<String>? _symbolsAfterToggle;

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async {
    if (_symbolsAfterToggle != null) {
      _symbols = _symbolsAfterToggle;
    }
    return _toggleResult ?? false;
  }
}

void main() {
  group('WatchlistNotifier', () {
    test(
      'should initialize state from repository\'s getSymbols on creation',
      () {
        final fakeRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930'},
        );

        final notifier = WatchlistNotifier(fakeRepository);

        expect(notifier.state, {'005930'});
      },
    );

    test(
      'should update state and return repository\'s result when toggling',
      () async {
        final fakeRepository = _FakeWatchlistRepository(
          toggleResult: true,
          symbolsAfterToggle: {'005930'},
        );
        final notifier = WatchlistNotifier(fakeRepository);

        final result = await notifier.toggleFavorite('005930');

        expect(result, isTrue);
        expect(notifier.state, contains('005930'));
      },
    );

    test(
      'should reflect repository state after a toggle removes a symbol',
      () async {
        final fakeRepository = _FakeWatchlistRepository(
          initialSymbols: {'005930'},
          toggleResult: false,
          symbolsAfterToggle: {},
        );
        final notifier = WatchlistNotifier(fakeRepository);

        final result = await notifier.toggleFavorite('005930');

        expect(result, isFalse);
        expect(notifier.state, isEmpty);
      },
    );
  });
}
