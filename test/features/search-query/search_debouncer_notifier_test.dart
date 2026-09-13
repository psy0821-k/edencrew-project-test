import 'package:edencrew_assignment_starter/entities/search/search_providers.dart';
import 'package:edencrew_assignment_starter/entities/search/search_repository.dart';
import 'package:edencrew_assignment_starter/entities/search/search_result.dart';
import 'package:edencrew_assignment_starter/features/search-query/search_debouncer_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 호출 횟수와 인자를 기록하는 fake. 디바운스 동작(호출 시점/횟수) 검증용.
/// 기존 `test/shared/utils/debouncer_test.dart`와 동일하게 실제 시간 대기
/// (`Future.delayed`) 방식을 사용한다 — `Debouncer`가 `Timer`를 직접 쓰고
/// 프로젝트에 시간을 가상으로 다루는 헬퍼가 별도로 도입되어 있지 않으므로
/// 기존 관례를 그대로 따른다.
class _RecordingSearchRepository implements SearchRepository {
  final List<String> calledQueries = [];

  @override
  Future<List<SearchResult>> search(String query) async {
    calledQueries.add(query);
    return [SearchResult(symbol: '005930', name: query, marketName: '코스피')];
  }
}

/// query별로 응답 지연 시간을 다르게 지정할 수 있는 fake.
/// 네트워크 지연 역전(늦게 보낸 요청이 먼저 응답)을 재현하는 데 사용한다.
class _DelayedSearchRepository implements SearchRepository {
  _DelayedSearchRepository(this._delayByQuery);

  final Map<String, Duration> _delayByQuery;

  @override
  Future<List<SearchResult>> search(String query) async {
    final delay = _delayByQuery[query] ?? Duration.zero;
    await Future<void>.delayed(delay);
    return [SearchResult(symbol: '005930', name: query, marketName: '코스피')];
  }
}

void main() {
  group('SearchDebouncerNotifier', () {
    test('2글자 이상 입력 후 300ms 초과 대기하면 정규화된 값으로 search가 1회 호출되고 '
        '상태가 결과로 갱신된다', () async {
      final fake = _RecordingSearchRepository();
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(searchDebouncerNotifierProvider.notifier);

      notifier.onQueryChanged('삼성 전자');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fake.calledQueries, ['삼성전자']);
      final state = container.read(searchDebouncerNotifierProvider);
      expect(state.value, isNotEmpty);
    });

    test('1글자만 입력하고 300ms 초과 대기해도 search가 호출되지 않는다', () async {
      final fake = _RecordingSearchRepository();
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(searchDebouncerNotifierProvider.notifier);

      notifier.onQueryChanged('삼');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fake.calledQueries, isEmpty);
    });

    test('2글자 이상을 연속 입력(짧은 간격)하면 마지막 입력값으로만 1회 호출된다', () async {
      final fake = _RecordingSearchRepository();
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(searchDebouncerNotifierProvider.notifier);

      notifier.onQueryChanged('삼성');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      notifier.onQueryChanged('삼성전');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      notifier.onQueryChanged('삼성전자');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fake.calledQueries, ['삼성전자']);
    });

    test('공백만 입력(정규화 후 길이 0)하면 search가 호출되지 않고 빈 목록으로 상태가 갱신된다', () async {
      final fake = _RecordingSearchRepository();
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(searchDebouncerNotifierProvider.notifier);

      notifier.onQueryChanged('   ');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fake.calledQueries, isEmpty);
      final state = container.read(searchDebouncerNotifierProvider);
      expect(state.value, isEmpty);
    });

    test(
      '이전 검색 요청이 새 검색 요청보다 늦게 응답하면 이전 응답으로 상태가 덮어써지지 않고 '
      '최신 검색 결과가 유지된다',
      () async {
        final fake = _DelayedSearchRepository({
          '삼성': const Duration(milliseconds: 500),
          '삼성전자': const Duration(milliseconds: 10),
        });
        final container = ProviderContainer(
          overrides: [searchRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(
          searchDebouncerNotifierProvider.notifier,
        );

        notifier.onQueryChanged('삼성');
        await Future<void>.delayed(const Duration(milliseconds: 350));
        notifier.onQueryChanged('삼성전자');
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final state = container.read(searchDebouncerNotifierProvider);
        expect(state.value!.first.name, '삼성전자');
      },
    );
  });
}
