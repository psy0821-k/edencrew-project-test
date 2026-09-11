import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_client.dart';
import '../../shared/config/data_source_mode.dart';
import 'mock_quote_repository.dart';
import 'network_quote_repository.dart';
import 'quote_repository.dart';

/// [ApiClient] 싱글턴. 여러 도메인 Repository가 공유합니다.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});

/// `dataSourceModeProvider`를 참조해 Mock/Network 구현체 중 하나를 선택합니다.
///
/// 전역 스위치가 기본 골격이지만, 테스트에서는 이 provider 자체를
/// `overrideWithValue`로 직접 교체하는 것도 가능합니다(개별 override는
/// 전역 모드보다 우선 적용됩니다).
final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return switch (ref.watch(dataSourceModeProvider)) {
    DataSourceMode.mock => MockQuoteRepository(),
    DataSourceMode.network => NetworkQuoteRepository(
        ref.watch(apiClientProvider),
      ),
  };
});
