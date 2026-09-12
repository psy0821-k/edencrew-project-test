import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/search/search_result.dart';
import '../features/search-list/search_input_field.dart';
import '../features/search-list/search_result_row.dart';
import '../features/search-query/query_normalizer.dart';
import '../features/search-query/search_debouncer_notifier.dart';
import '../widgets/empty_state_view.dart';

const int _minQueryLength = 2;

/// 검색 화면. searchDebouncerNotifierProvider를 구독해
/// 초기/결과/결과없음/에러 상태를 전환한다.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _rawQuery = ''; // 사용자가 입력한 원본 문자열(정규화 전). 결과없음 문구에 그대로 사용.

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    setState(() => _rawQuery = raw);
    ref.read(searchDebouncerNotifierProvider.notifier).onQueryChanged(raw);
  }

  void _onClear() {
    _controller.clear();
    setState(() => _rawQuery = '');
    ref.read(searchDebouncerNotifierProvider.notifier).onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchDebouncerNotifierProvider);
    final isValidQuery = normalizeQuery(_rawQuery).length >= _minQueryLength;

    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Column(
        children: [
          SearchInputField(
            controller: _controller,
            onChanged: _onChanged,
            onClear: _onClear,
          ),
          Expanded(
            child: _buildBody(searchState, isValidQuery),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<List<SearchResult>> searchState,
    bool isValidQuery,
  ) {
    if (!isValidQuery) {
      return const EmptyStateView(
        iconAsset: 'assets/icons/ico_search.svg',
        title: '종목을 검색해 보세요',
        caption: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다',
      );
    }

    return searchState.when(
      data: (results) {
        if (results.isEmpty) {
          return EmptyStateView(
            iconAsset: 'assets/icons/ico_search_empty.svg',
            title: '검색 결과가 없습니다',
            caption: "'$_rawQuery'와 일치하는 검색 결과를 찾지 못했습니다.",
          );
        }

        final query = normalizeQuery(_rawQuery);
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            return SearchResultRow(result: results[index], query: query);
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const EmptyStateView(
        iconAsset: 'assets/icons/ico_search_empty.svg',
        title: '검색 결과가 없습니다',
        caption: '검색 중 문제가 발생했습니다',
      ),
    );
  }
}
