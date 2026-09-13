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
// Figma 실측 높이는 60px이지만, 고정값으로 두면 접근성 폰트 확대 시
// RenderFlex overflow가 발생한다(실기기 확인됨). WatchlistRow와 동일하게
// dimens.rowMinHeight(56)를 최소값으로만 강제해 폰트가 커지면 행이 자연스럽게 늘어나게 한다.

/// 검색 결과 행 하나. 종목명(검색어 일치 구간 하이라이트) + 종목코드 · 시장 + 별 아이콘 표시.
class SearchResultRow extends ConsumerWidget {
  const SearchResultRow({
    super.key,
    required this.result,
    required this.query,
    required this.onToggleFavorite,
    required this.onTap,
  });

  /// 표시할 검색 결과 하나.
  final SearchResult result;

  /// 하이라이트 계산에 쓰이는 정규화된 검색어. (normalizeQuery 결과를 그대로 전달)
  final String query;

  /// 별 아이콘 탭 콜백. Row는 토글 로직을 모르고 symbol만 전달한다.
  final void Function(String symbol) onToggleFavorite;

  /// 행(별 아이콘 영역 제외) 탭 콜백. symbol만 전달한다.
  final void Function(String symbol) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dimens = context.dimens;
    final isFavorite = ref.watch(isFavoriteProvider(result.symbol));
    final baseStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontWeight: AppTypography.medium,
      fontSize: _nameFontSize,
      height: _nameLineHeight / _nameFontSize,
      letterSpacing: _nameLetterSpacing,
      color: colors.textPrimary,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(result.symbol),
      child: Container(
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        padding: EdgeInsets.symmetric(
          vertical: dimens.space3,
          horizontal: dimens.space4,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: dimens.borderHairline,
              color: colors.borderSubtle,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: dimens.space2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggleFavorite(result.symbol),
              child: SvgPicture.asset(
                isFavorite
                    ? 'assets/icons/ico_star_filled.svg'
                    : 'assets/icons/ico_star.svg',
                width: dimens.iconMd,
                height: dimens.iconMd,
                colorFilter: ColorFilter.mode(
                  isFavorite ? colors.favoriteActive : colors.favoriteInactive,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
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
