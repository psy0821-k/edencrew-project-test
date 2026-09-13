import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/search/search_result.dart';
import '../entities/watchlist/watchlist_providers.dart';
import '../features/search-list/search_input_field.dart';
import '../features/search-list/search_result_row.dart';
import '../features/search-query/query_normalizer.dart';
import '../features/search-query/search_debouncer_notifier.dart';
import '../shared/state/pending_symbols_notifier.dart';
import '../theme/theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/favorite_toast.dart';
import '../widgets/search_result_skeleton_row.dart';
import 'stock_detail_page.dart';

const int _skeletonRowCount = 6;

const int _minQueryLength = 2;
// Figma 스펙상 검색바 컨테이너는 60px(8/12 비대칭 padding)이지만, 관심 탭 헤더(WatchlistHeader)가
// 52px 고정이라 그대로 적용하면 관심↔검색 탭 전환 시 하단 콘텐츠 시작 위치가 8px 어긋난다.
// 탭 전환 시 콘텐츠가 흔들리지 않도록 WatchlistHeader와 동일한 52px로 맞추고,
// 그 안에서 SearchInputField(40px)를 중앙 정렬해 위아래 여백을 균등하게 둔다.
// (AppDimens에 헤더 높이 토큰이 없어 로컬 상수로 둔다.)
const double _headerHeight = 52;

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
  Timer? _toastTimer;

  @override
  void dispose() {
    _controller.dispose();
    _toastTimer?.cancel();
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

  Future<void> _onToggleFavorite(String symbol) async {
    await ref.read(pendingSymbolsProvider.notifier).run(symbol, () async {
      final isNowFavorite = await ref
          .read(watchlistProvider.notifier)
          .toggleFavorite(symbol);
      if (!mounted) return;
      _toastTimer = showFavoriteToast(context, isNowFavorite);
    });
  }

  void _onResultTap(String symbol) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StockDetailPage(symbol: symbol)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchDebouncerNotifierProvider);
    final isValidQuery = normalizeQuery(_rawQuery).length >= _minQueryLength;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: _headerHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.dimens.space4,
                ),
                child: Center(
                  child: SearchInputField(
                    controller: _controller,
                    onChanged: _onChanged,
                    onClear: _onClear,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildBody(searchState, isValidQuery),
            ),
          ],
        ),
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
            caption: "'$_rawQuery'와\n일치하는 검색 결과를 찾지 못했습니다.",
          );
        }

        final query = normalizeQuery(_rawQuery);
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            return SearchResultRow(
              result: results[index],
              query: query,
              onToggleFavorite: _onToggleFavorite,
              onTap: _onResultTap,
            );
          },
        );
      },
      loading: () => ListView.builder(
        itemCount: _skeletonRowCount,
        itemBuilder: (context, index) => const SearchResultSkeletonRow(),
      ),
      error: (error, stackTrace) => const EmptyStateView(
        iconAsset: 'assets/icons/ico_search_empty.svg',
        title: '검색 결과가 없습니다',
        caption: '검색 중 문제가 발생했습니다',
      ),
    );
  }
}
