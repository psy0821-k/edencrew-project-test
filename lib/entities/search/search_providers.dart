import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/config/data_source_mode.dart';
import '../quote/quote_providers.dart';
import '../stock_meta/stock_meta_providers.dart';
import 'mock_search_repository.dart';
import 'network_search_repository.dart';
import 'search_repository.dart';

/// `dataSourceModeProvider`를 참조해 Mock/Network 구현체 중 하나를 선택합니다.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return switch (ref.watch(dataSourceModeProvider)) {
    DataSourceMode.mock => MockSearchRepository(),
    DataSourceMode.network => NetworkSearchRepository(
      ref.watch(apiClientProvider),
      ref.watch(stockMetaRepositoryProvider),
    ),
  };
});
