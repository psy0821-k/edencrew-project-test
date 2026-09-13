import 'dart:async';

import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_providers.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/daily_quote_repository.dart';
import 'package:edencrew_assignment_starter/entities/daily_quote/period.dart';
import 'package:edencrew_assignment_starter/features/stock-detail/stock_detail_daily_quote_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControllableDailyQuoteRepository implements DailyQuoteRepository {
  final Map<Period, Completer<List<DailyQuote>>> _completers = {};
  final List<Period> requestedPeriods = [];

  Completer<List<DailyQuote>> completerFor(Period period) =>
      _completers.putIfAbsent(period, () => Completer());

  void completeWith(Period period, List<DailyQuote> quotes) {
    completerFor(period).complete(quotes);
  }

  void failWith(Period period, Object error) {
    completerFor(period).completeError(error);
  }

  @override
  Future<List<DailyQuote>> fetchQuotes(String symbol, Period period) {
    requestedPeriods.add(period);
    return completerFor(period).future;
  }
}

final Map<Period, List<DailyQuote>> _quotesCache = {};

List<DailyQuote> _quotesFor(Period period) =>
    _quotesCache.putIfAbsent(period, () => _buildQuotesFor(period));

List<DailyQuote> _buildQuotesFor(Period period) => [
  DailyQuote(
    date: '20260911',
    closePrice: period.requiredPageCount * 1000,
    openPrice: 70000,
    highPrice: 70800,
    lowPrice: 69900,
    volume: 12345678,
  ),
];

void main() {
  group('StockDetailDailyQuoteNotifier', () {
    test('symbol을 구독하면 selectedPeriodProvider의 현재 기간으로 최초 조회를 수행한다', () async {
      final repository = _ControllableDailyQuoteRepository();
      final container = ProviderContainer(
        overrides: [dailyQuoteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(stockDetailDailyQuoteProvider('005930'), (_, _) {});
      repository.completeWith(Period.oneMonth, _quotesFor(Period.oneMonth));
      await pumpEventQueue();

      final state = container.read(stockDetailDailyQuoteProvider('005930'));
      expect(state.quotes, _quotesFor(Period.oneMonth));
      expect(repository.requestedPeriods, [Period.oneMonth]);
    });

    test('selectedPeriodProvider가 바뀌면 자동으로 새 기간의 데이터를 다시 조회한다', () async {
      final repository = _ControllableDailyQuoteRepository();
      final container = ProviderContainer(
        overrides: [dailyQuoteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(stockDetailDailyQuoteProvider('005930'), (_, _) {});
      repository.completeWith(Period.oneMonth, _quotesFor(Period.oneMonth));
      await pumpEventQueue();

      container.read(selectedPeriodProvider.notifier).state =
          Period.threeMonths;
      repository.completeWith(
        Period.threeMonths,
        _quotesFor(Period.threeMonths),
      );
      await pumpEventQueue();

      final state = container.read(stockDetailDailyQuoteProvider('005930'));
      expect(state.quotes, _quotesFor(Period.threeMonths));
      expect(repository.requestedPeriods, [
        Period.oneMonth,
        Period.threeMonths,
      ]);
    });

    test('새 기간 조회 중에는 isRefreshing이 true가 되지만 quotes는 이전 값을 유지한다', () async {
      final repository = _ControllableDailyQuoteRepository();
      final container = ProviderContainer(
        overrides: [dailyQuoteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(stockDetailDailyQuoteProvider('005930'), (_, _) {});
      repository.completeWith(Period.oneMonth, _quotesFor(Period.oneMonth));
      await pumpEventQueue();

      container.read(selectedPeriodProvider.notifier).state =
          Period.threeMonths;
      await pumpEventQueue();

      final state = container.read(stockDetailDailyQuoteProvider('005930'));
      expect(state.isRefreshing, isTrue);
      expect(state.quotes, _quotesFor(Period.oneMonth));
    });

    test(
      'oneMonth 조회 직후 바로 oneYear로 전환해 두 요청이 겹치면, 두 응답이 모두 도착한 뒤 '
      '최종 quotes는 마지막으로 선택한 oneYear의 데이터만 반영된다',
      () async {
        final repository = _ControllableDailyQuoteRepository();
        final container = ProviderContainer(
          overrides: [
            dailyQuoteRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        container.listen(stockDetailDailyQuoteProvider('005930'), (_, _) {});
        await pumpEventQueue();

        container.read(selectedPeriodProvider.notifier).state =
            Period.oneYear;
        await pumpEventQueue();

        // 늦게 요청한 oneYear가 먼저 응답하고, 먼저 요청한 oneMonth가 나중에 응답한다.
        repository.completeWith(Period.oneYear, _quotesFor(Period.oneYear));
        await pumpEventQueue();
        repository.completeWith(Period.oneMonth, _quotesFor(Period.oneMonth));
        await pumpEventQueue();

        final state = container.read(stockDetailDailyQuoteProvider('005930'));
        expect(state.quotes, _quotesFor(Period.oneYear));
      },
    );

    test('탭 전환 중 조회가 실패하면 error에 값이 채워지고 quotes는 이전 값을 유지한다', () async {
      final repository = _ControllableDailyQuoteRepository();
      final container = ProviderContainer(
        overrides: [dailyQuoteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(stockDetailDailyQuoteProvider('005930'), (_, _) {});
      repository.completeWith(Period.oneMonth, _quotesFor(Period.oneMonth));
      await pumpEventQueue();

      container.read(selectedPeriodProvider.notifier).state =
          Period.threeMonths;
      // fetch가 dailyQuoteProvider를 실제로 구독할 시간을 한 틱 준 뒤에
      // 실패시켜야 한다(구독 전에 completeError가 호출되면 아직 아무도
      // 듣고 있지 않은 Future의 에러가 uncaught로 보고될 수 있다).
      await pumpEventQueue();
      repository.failWith(Period.threeMonths, Exception('network error'));
      await pumpEventQueue();

      final state = container.read(stockDetailDailyQuoteProvider('005930'));
      expect(state.error, isNotNull);
      expect(state.quotes, _quotesFor(Period.oneMonth));
    });

    test('최초 조회(quotes가 아직 없는 상태)가 실패하면 error가 채워지고 quotes는 null로 유지된다', () async {
      final repository = _ControllableDailyQuoteRepository();
      final container = ProviderContainer(
        overrides: [dailyQuoteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(stockDetailDailyQuoteProvider('005930'), (_, _) {});
      repository.failWith(Period.oneMonth, Exception('network error'));
      await pumpEventQueue();

      final state = container.read(stockDetailDailyQuoteProvider('005930'));
      expect(state.error, isNotNull);
      expect(state.quotes, isNull);
    });
  });
}
