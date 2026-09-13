import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/search/search_providers.dart';
import '../../entities/search/search_result.dart';
import '../../shared/utils/debouncer.dart';
import 'query_normalizer.dart';

/// 사용자가 타이핑한 원본 문자열을 받아 [Debouncer](300ms)로 지연시킨 뒤,
/// 정규화 결과가 2글자 미만이면 요청하지 않고, 2글자 이상이면
/// `searchRepositoryProvider.search(...)`를 호출해 상태를 갱신합니다.
class SearchDebouncerNotifier extends AsyncNotifier<List<SearchResult>> {
  static const _minQueryLength = 2;

  final Debouncer _debouncer = Debouncer(const Duration(milliseconds: 300));

  /// 검색 요청마다 증가하는 세대 번호. 응답이 도착했을 때 이 값이 여전히
  /// 최신 요청인지 확인해, 네트워크 지연 역전으로 오래된 응답이 더 늦게
  /// 도착해도 최신 검색 결과를 덮어쓰지 않도록 한다.
  int _requestGeneration = 0;

  @override
  Future<List<SearchResult>> build() async {
    ref.onDispose(_debouncer.dispose);
    return [];
  }

  /// 사용자가 타이핑할 때마다 호출합니다. 원본(정규화 전) 문자열을 그대로 전달합니다.
  void onQueryChanged(String raw) {
    _debouncer.run(() => _search(raw));
  }

  Future<void> _search(String raw) async {
    final generation = ++_requestGeneration;
    final normalized = normalizeQuery(raw);

    if (normalized.length < _minQueryLength) {
      if (generation == _requestGeneration) state = const AsyncData([]);
      return;
    }

    if (generation == _requestGeneration) state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(searchRepositoryProvider).search(normalized),
    );
    if (generation == _requestGeneration) state = result;
  }
}

final searchDebouncerNotifierProvider =
    AsyncNotifierProvider<SearchDebouncerNotifier, List<SearchResult>>(
      SearchDebouncerNotifier.new,
    );
