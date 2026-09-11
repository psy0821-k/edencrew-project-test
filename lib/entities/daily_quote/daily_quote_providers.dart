import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/config/data_source_mode.dart';
import '../quote/quote_providers.dart';
import 'daily_quote_repository.dart';
import 'mock_daily_quote_repository.dart';
import 'network_daily_quote_repository.dart';

/// `dataSourceModeProvider`를 참조해 Mock/Network 구현체 중 하나를 선택합니다.
final dailyQuoteRepositoryProvider = Provider<DailyQuoteRepository>((ref) {
  return switch (ref.watch(dataSourceModeProvider)) {
    DataSourceMode.mock => MockDailyQuoteRepository(),
    DataSourceMode.network => NetworkDailyQuoteRepository(
      ref.watch(apiClientProvider),
    ),
  };
});
