import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_providers.dart';
import 'package:edencrew_assignment_starter/entities/watchlist/watchlist_repository.dart';
import 'package:edencrew_assignment_starter/pages/watchlist_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository implements WatchlistRepository {
  final Set<String> _symbols = {};

  @override
  Set<String> getSymbols() => _symbols;

  @override
  bool isFavorite(String symbol) => _symbols.contains(symbol);

  @override
  Future<bool> toggleFavorite(String symbol) async => false;
}

void main() {
  group('WatchlistPage', () {
    testWidgets(
      'should show the empty state screen when there are zero watchlist items',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(
                _FakeWatchlistRepository(),
              ),
            ],
            child: const MaterialApp(home: WatchlistPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('관심 종목이 없습니다'), findsOneWidget);
      },
    );
  });
}
