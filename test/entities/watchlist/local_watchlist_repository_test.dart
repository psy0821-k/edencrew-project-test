import 'package:edencrew_assignment_starter/entities/watchlist/local_watchlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalWatchlistRepository', () {
    test('should return empty set when no watchlist stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = LocalWatchlistRepository(prefs);

      final symbols = repository.getSymbols();

      expect(symbols, isEmpty);
    });

    test(
      'should return true and persist symbol when toggling an unregistered symbol',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = LocalWatchlistRepository(prefs);

        final result = await repository.toggleFavorite('005930');

        expect(result, isTrue);
        expect(repository.isFavorite('005930'), isTrue);
      },
    );

    test(
      'should return false and remove symbol when toggling an already-registered symbol',
      () async {
        SharedPreferences.setMockInitialValues({
          'watchlist_symbols': ['005930'],
        });
        final prefs = await SharedPreferences.getInstance();
        final repository = LocalWatchlistRepository(prefs);

        final result = await repository.toggleFavorite('005930');

        expect(result, isFalse);
        expect(repository.isFavorite('005930'), isFalse);
      },
    );

    test(
      'should keep symbol across repository instances backed by the same SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final firstRepository = LocalWatchlistRepository(prefs);
        await firstRepository.toggleFavorite('005930');

        final secondRepository = LocalWatchlistRepository(prefs);

        expect(secondRepository.getSymbols(), contains('005930'));
      },
    );

    test(
      'should not affect stored symbols when mutating the returned set',
      () async {
        SharedPreferences.setMockInitialValues({
          'watchlist_symbols': ['005930'],
        });
        final prefs = await SharedPreferences.getInstance();
        final repository = LocalWatchlistRepository(prefs);

        final symbols = repository.getSymbols();
        symbols.add('000000');

        expect(repository.getSymbols(), isNot(contains('000000')));
      },
    );

    test(
      'should toggle correctly when multiple symbols are already registered',
      () async {
        SharedPreferences.setMockInitialValues({
          'watchlist_symbols': ['005930', '035720'],
        });
        final prefs = await SharedPreferences.getInstance();
        final repository = LocalWatchlistRepository(prefs);

        final result = await repository.toggleFavorite('035720');

        expect(result, isFalse);
        expect(repository.getSymbols(), {'005930'});
      },
    );
  });
}
