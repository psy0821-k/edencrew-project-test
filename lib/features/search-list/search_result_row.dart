import 'package:flutter/material.dart';

import '../../entities/search/search_result.dart';
import '../../theme/theme.dart';
import '../search-query/highlight_matcher.dart';

const double _nameFontSize = 15;
const double _nameLineHeight = 20;
const double _nameLetterSpacing = -0.1;
const double _metaFontSize = 11;
const double _metaLineHeight = 14;
const double _rowVerticalPadding = 12;
const double _rowHorizontalPadding = 16;

/// 검색 결과 행 하나. 종목명(검색어 일치 구간 하이라이트) + 종목코드 · 시장 표시.
/// 별 아이콘/탭 인터랙션은 이후 이슈(#33, #35)에서 추가.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({super.key, required this.result, required this.query});

  /// 표시할 검색 결과 하나.
  final SearchResult result;

  /// 하이라이트 계산에 쓰이는 정규화된 검색어. (normalizeQuery 결과를 그대로 전달)
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
