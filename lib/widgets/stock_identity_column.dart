import 'package:flutter/material.dart';

import '../theme/theme.dart';

const double _nameFontSize = 15;
const double _nameLineHeight = 20;
const double _nameLetterSpacing = -0.1;
const double _metaFontSize = 11;
const double _metaLineHeight = 14;

/// 종목 행의 좌측 "종목명 + 종목코드 · 시장" 텍스트 블록.
/// WatchlistRow, SearchResultRow가 공통으로 사용한다.
class StockIdentityColumn extends StatelessWidget {
  const StockIdentityColumn({
    super.key,
    required this.name,
    required this.symbol,
    required this.marketName,
    this.highlightRange,
  });

  /// 종목명. 예: `삼성전자`
  final String name;

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 거래소명. 예: `코스피`
  final String marketName;

  /// 종목명 안에서 하이라이트할 구간(검색 화면에서만 사용). null이면 하이라이트 없이 표시.
  final ({int start, int end})? highlightRange;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          _buildNameSpan(baseStyle, colors),
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
              TextSpan(text: symbol),
              TextSpan(text: ' · $marketName'),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  TextSpan _buildNameSpan(TextStyle baseStyle, AppColors colors) {
    final range = highlightRange;
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
