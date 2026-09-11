import 'package:edencrew_assignment_starter/entities/search/mock_search_repository.dart';
import 'package:edencrew_assignment_starter/entities/search/network_search_repository.dart';
import 'package:edencrew_assignment_starter/entities/search/search_providers.dart';
import 'package:edencrew_assignment_starter/entities/search/search_repository.dart';
import 'package:edencrew_assignment_starter/entities/search/search_result.dart';
import 'package:edencrew_assignment_starter/shared/config/data_source_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSearchRepository implements SearchRepository {
  @override
  Future<List<SearchResult>> search(String query) async => const [
    SearchResult(symbol: '005930', name: '삼성전자', marketName: '코스피'),
  ];
}

void main() {
  group('searchRepositoryProvider', () {
    test('dataSourceMode 기본값(network)일 때 NetworkSearchRepository를 반환한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(searchRepositoryProvider);

      expect(repository, isA<NetworkSearchRepository>());
    });

    test('dataSourceMode를 mock으로 override하면 MockSearchRepository를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          dataSourceModeProvider.overrideWithValue(DataSourceMode.mock),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(searchRepositoryProvider);

      expect(repository, isA<MockSearchRepository>());
    });

    test(
      '전역 모드가 network여도 searchRepositoryProvider를 개별 override하면 그 값이 우선한다',
      () {
        final fake = _FakeSearchRepository();
        final container = ProviderContainer(
          overrides: [searchRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final repository = container.read(searchRepositoryProvider);

        expect(repository, same(fake));
      },
    );
  });
}
