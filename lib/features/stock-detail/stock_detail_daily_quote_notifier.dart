import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/daily_quote/daily_quote.dart';
import '../../entities/daily_quote/daily_quote_providers.dart';
import '../../entities/daily_quote/period.dart';

/// [StockDetailDailyQuoteNotifier]가 노출하는 상태.
///
/// [quotes]는 마지막으로 성공한 조회 결과를 담고 있으며, 기간 탭을 전환해도
/// 새 데이터가 도착하기 전까지는 이전 값을 그대로 유지합니다(stale-while-revalidate).
class StockDetailDailyQuoteState {
  const StockDetailDailyQuoteState({
    required this.quotes,
    required this.isRefreshing,
    required this.error,
  });

  /// 마지막으로 성공한 조회 결과. 최초 조회가 아직 완료되지 않았으면 null.
  final List<DailyQuote>? quotes;

  /// 현재 기간의 데이터를 조회하는 중이면 true.
  final bool isRefreshing;

  /// 가장 최근 조회가 실패했을 때만 값이 채워집니다. [quotes]는 실패해도 유지됩니다.
  final Object? error;

  StockDetailDailyQuoteState copyWith({
    List<DailyQuote>? quotes,
    bool? isRefreshing,
    Object? error,
    bool clearError = false,
  }) {
    return StockDetailDailyQuoteState(
      quotes: quotes ?? this.quotes,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// `dailyQuoteProvider`(symbol, selectedPeriodProvider)를 감싸 "기존 데이터
/// 유지 + 요청 세대 검증"을 구현하는 Notifier.
///
/// `SearchDebouncerNotifier`와 동일한 세대 카운터 패턴으로, 기간 탭을 빠르게
/// 연속 전환해 응답이 역순으로 도착해도 마지막으로 선택한 기간의 데이터만
/// 최종 상태에 반영되도록 방어합니다.
class StockDetailDailyQuoteNotifier
    extends FamilyNotifier<StockDetailDailyQuoteState, String> {
  int _requestGeneration = 0;

  // build()가 state를 반환하기 전에는 Notifier.state에 접근할 수 없으므로,
  // 기간 탭 전환으로 build()가 재실행될 때도 이전 quotes를 유지(stale-while-
  // revalidate)하기 위해 마지막으로 성공한 값을 별도로 들고 있는다.
  List<DailyQuote>? _lastQuotes;

  @override
  StockDetailDailyQuoteState build(String symbol) {
    final period = ref.watch(selectedPeriodProvider);
    Future.microtask(() => _fetch(symbol, period));
    return StockDetailDailyQuoteState(
      quotes: _lastQuotes,
      isRefreshing: true,
      error: null,
    );
  }

  Future<void> _fetch(String symbol, Period period) async {
    final generation = ++_requestGeneration;

    try {
      final quotes = await ref.read(
        dailyQuoteProvider((symbol, period)).future,
      );
      if (generation != _requestGeneration) return;
      _lastQuotes = quotes;
      state = state.copyWith(
        quotes: quotes,
        isRefreshing: false,
        clearError: true,
      );
    } catch (error) {
      if (generation != _requestGeneration) return;
      state = state.copyWith(isRefreshing: false, error: error);
    }
  }
}

final stockDetailDailyQuoteProvider =
    NotifierProvider.family<
      StockDetailDailyQuoteNotifier,
      StockDetailDailyQuoteState,
      String
    >(StockDetailDailyQuoteNotifier.new);
