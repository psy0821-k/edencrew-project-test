import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../entities/watchlist/watchlist_item.dart';
import '../../shared/utils/number_formatter.dart';
import '../../shared/utils/price_change_formatter.dart';
import '../../theme/theme.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/stock_identity_column.dart';

// AppDimens에 폰트 크기·행간·스켈레톤 너비 토큰이 없어 Figma 실측값을 로컬 상수로 둔다.
const double _identityFontSize = 15;
const double _identityLineHeight = 20;
const double _identityLetterSpacing = -0.1;
const double _metaFontSize = 11;
const double _metaLineHeight = 14;
const double _priceSkeletonWidth = 60;
const double _changeSkeletonWidth = 80;
const double _closeIconSize = 20;

/// 관심 화면의 종목 행 하나. (`01 · 관심`의 일반 행)
/// 행을 탭하면 상세 화면으로 이동하고, close 아이콘을 탭하면 관심을 해제한다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRemoveTap,
  });

  final WatchlistItem item;

  /// 행(close 아이콘 영역 제외) 탭 콜백. symbol만 전달한다.
  final void Function(String symbol) onTap;

  /// close 아이콘 탭 콜백. symbol만 전달한다. Row는 해제 로직을 모른다.
  final void Function(String symbol) onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final quote = item.quote;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(item.symbol),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StockIdentityColumn(
              name: item.stockMeta.name,
              symbol: item.symbol,
              marketName: item.stockMeta.marketName,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (quote != null)
                      Text(
                        NumberFormatter.comma(quote.currentPrice),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: AppTypography.medium,
                          fontSize: _identityFontSize,
                          height: _identityLineHeight / _identityFontSize,
                          letterSpacing: _identityLetterSpacing,
                          color: colors.textPrimary,
                        ),
                      )
                    else
                      const SkeletonBox(
                        width: _priceSkeletonWidth,
                        height: _identityLineHeight,
                      ),
                    const SizedBox(height: 2),
                    if (quote != null)
                      Builder(
                        builder: (context) {
                          final change = formatPriceChange(quote, colors);
                          return Text(
                            change.text,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontWeight: AppTypography.regular,
                              fontSize: _metaFontSize,
                              height: _metaLineHeight / _metaFontSize,
                              color: change.color,
                            ),
                          );
                        },
                      )
                    else
                      const SkeletonBox(
                        width: _changeSkeletonWidth,
                        height: _metaLineHeight,
                      ),
                  ],
                ),
                SizedBox(width: dimens.space2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onRemoveTap(item.symbol),
                  child: SvgPicture.asset(
                    'assets/icons/ico_close.svg',
                    width: _closeIconSize,
                    height: _closeIconSize,
                    colorFilter: ColorFilter.mode(
                      colors.textTertiary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
