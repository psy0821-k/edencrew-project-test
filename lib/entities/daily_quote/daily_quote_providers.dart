import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/config/data_source_mode.dart';
import '../quote/quote_providers.dart';
import 'daily_quote.dart';
import 'daily_quote_repository.dart';
import 'mock_daily_quote_repository.dart';
import 'network_daily_quote_repository.dart';
import 'period.dart';

/// `dataSourceModeProvider`를 참조해 Mock/Network 구현체 중 하나를 선택합니다.
final dailyQuoteRepositoryProvider = Provider<DailyQuoteRepository>((ref) {
  return switch (ref.watch(dataSourceModeProvider)) {
    DataSourceMode.mock => MockDailyQuoteRepository(),
    DataSourceMode.network => NetworkDailyQuoteRepository(
      ref.watch(apiClientProvider),
    ),
  };
});

/// 상세 화면에서 현재 선택된 기간 탭. 기본값 `Period.oneMonth`.
final selectedPeriodProvider = StateProvider<Period>((ref) => Period.oneMonth);

/// (symbol, period) 조합의 일별 시세를 조회합니다. 차트·요약 카드·표 전용.
final dailyQuoteProvider =
    FutureProvider.family<List<DailyQuote>, (String, Period)>((
      ref,
      args,
    ) async {
      final repository = ref.watch(dailyQuoteRepositoryProvider);
      return repository.fetchQuotes(args.$1, args.$2);
    });
