import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../entities/search/search_result.dart';
import '../../entities/watchlist/watchlist_providers.dart';
import '../../theme/theme.dart';
import '../search-query/highlight_matcher.dart';

const double _nameFontSize = 15;
const double _nameLineHeight = 20;
const double _nameLetterSpacing = -0.1;
const double _metaFontSize = 11;
const double _metaLineHeight = 14;
const double _rowVerticalPadding = 12;
const double _rowHorizontalPadding = 16;
const double _starIconSize = 20;
const double _starGap = 8;

/// 검색 결과 행 하나. 종목명(검색어 일치 구간 하이라이트) + 종목코드 · 시장 + 별 아이콘 표시.
/// 행 전체 탭 인터랙션(상세 이동)은 이후 이슈(#35)에서 추가.
class SearchResultRow extends ConsumerWidget {
  const SearchResultRow({
    super.key,
    required this.result,
    required this.query,
    required this.onToggleFavorite,
  });

  /// 표시할 검색 결과 하나.
  final SearchResult result;

  /// 하이라이트 계산에 쓰이는 정규화된 검색어. (normalizeQuery 결과를 그대로 전달)
  final String query;

  /// 별 아이콘 탭 콜백. Row는 토글 로직을 모르고 symbol만 전달한다.
  final void Function(String symbol) onToggleFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isFavorite = ref.watch(isFavoriteProvider(result.symbol));
    final baseStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontWeight: AppTypography.medium,
      fontSize: _nameFontSize,
      height: _nameLineHeight / _nameFontSize,
      letterSpacing: _nameLetterSpacing,
      color: colors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _rowVerticalPadding,
        horizontal: _rowHorizontalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  _buildNameSpan(result.name, query, baseStyle, colors),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: AppTypography.regular,
                      fontSize: _metaFontSize,
                      height: _metaLineHeight / _metaFontSize,
                      color: colors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: result.symbol),
                      TextSpan(text: ' · ${result.marketName}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _starGap),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggleFavorite(result.symbol),
            child: SvgPicture.asset(
              isFavorite
                  ? 'assets/icons/ico_star_filled.svg'
                  : 'assets/icons/ico_star.svg',
              width: _starIconSize,
              height: _starIconSize,
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildNameSpan(
    String name,
    String query,
    TextStyle baseStyle,
    AppColors colors,
  ) {
    final range = findHighlightRange(name, query);
    if (range == null) {
      return TextSpan(text: name, style: baseStyle);
    }

    return TextSpan(
      style: baseStyle,
      children: [
        if (range.start > 0) TextSpan(text: name.substring(0, range.start)),
        TextSpan(
          text: name.substring(range.start, range.end),
          style: TextStyle(color: colors.searchHighlight),
        ),
        if (range.end < name.length) TextSpan(text: name.substring(range.end)),
      ],
    );
  }
}
