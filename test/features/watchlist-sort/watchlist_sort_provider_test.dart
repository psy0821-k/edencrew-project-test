import 'package:edencrew_assignment_starter/features/watchlist-sort/sort_criteria.dart';
import 'package:edencrew_assignment_starter/features/watchlist-sort/watchlist_sort_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('watchlistSortCriteriaProvider', () {
    test(
      'should return SortCriteria.priceDesc when read in its initial state',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = container.read(watchlistSortCriteriaProvider);

        expect(state, SortCriteria.priceDesc);
      },
    );

    test(
      'should immediately return SortCriteria.nameAsc when read after the state is changed to SortCriteria.nameAsc',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(watchlistSortCriteriaProvider.notifier).state =
            SortCriteria.nameAsc;

        expect(
          container.read(watchlistSortCriteriaProvider),
          SortCriteria.nameAsc,
        );
      },
    );

    test(
      'should automatically notify a subscribed listener with the updated value without resubscribing when the state changes',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(
          watchlistSortCriteriaProvider,
          (previous, next) {},
        );
        expect(sub.read(), SortCriteria.priceDesc);

        container.read(watchlistSortCriteriaProvider.notifier).state =
            SortCriteria.changeRateDesc;

        expect(sub.read(), SortCriteria.changeRateDesc);
      },
    );
  });
}
