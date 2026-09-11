import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/config/data_source_mode.dart';
import '../quote/quote_providers.dart';
import 'mock_stock_meta_repository.dart';
import 'network_stock_meta_repository.dart';
import 'stock_meta_repository.dart';

/// `dataSourceModeProvider`를 참조해 Mock/Network 구현체 중 하나를 선택합니다.
final stockMetaRepositoryProvider = Provider<StockMetaRepository>((ref) {
  return switch (ref.watch(dataSourceModeProvider)) {
    DataSourceMode.mock => MockStockMetaRepository(),
    DataSourceMode.network => NetworkStockMetaRepository(
      ref.watch(apiClientProvider),
    ),
  };
});
