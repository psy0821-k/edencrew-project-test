import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../entities/stock_meta/stock_meta.dart';
import '../../entities/watchlist/watchlist_providers.dart';
import '../../shared/state/pending_symbols_notifier.dart';
import '../../theme/theme.dart';
import '../../widgets/favorite_toast.dart';
import '../../widgets/skeleton_box.dart';

const double _nameSkeletonWidth = 100;
const double _nameSkeletonHeight = 20;
const double _captionSkeletonWidth = 80;
const double _captionSkeletonHeight = 14;
const double _nameFontSize = 15;
const double _nameLineHeight = 20;
const double _nameLetterSpacing = -0.1;
const double _captionFontSize = 11;
const double _captionLineHeight = 14;

/// 상세 화면 상단 고정 헤더. 뒤로가기 + 종목명 + "종목코드 · 시장" + 관심 버튼.
/// StockMeta 로딩 전에는 종목명/시장 영역을 SkeletonBox로 표시한다.
class StockDetailHeader extends ConsumerStatefulWidget {
  const StockDetailHeader({
    super.key,
    required this.symbol,
    required this.stockMeta,
  });

  final String symbol;
  final AsyncValue<StockMeta> stockMeta;

  @override
  ConsumerState<StockDetailHeader> createState() => _StockDetailHeaderState();
}

class _StockDetailHeaderState extends ConsumerState<StockDetailHeader> {
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _onToggleFavorite() async {
    await ref.read(pendingSymbolsProvider.notifier).run(
      widget.symbol,
      () async {
        final isNowFavorite = await ref
            .read(watchlistProvider.notifier)
            .toggleFavorite(widget.symbol);
        if (!mounted) return;
        _toastTimer = showFavoriteToast(
          context,
          isNowFavorite,
          showTabBarGap: false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final isFavorite = ref.watch(isFavoriteProvider(widget.symbol));

    return Container(
      constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
      padding: EdgeInsets.symmetric(horizontal: dimens.space2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: dimens.borderHairline,
            color: colors.borderSubtle,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/ico_back.svg',
              width: dimens.iconMd,
              height: dimens.iconMd,
              colorFilter: ColorFilter.mode(
                colors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: widget.stockMeta.when(
              data: (meta) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.name,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: AppTypography.medium,
                      fontSize: _nameFontSize,
                      height: _nameLineHeight / _nameFontSize,
                      letterSpacing: _nameLetterSpacing,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${meta.symbol} · ${meta.marketName}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: AppTypography.regular,
                      fontSize: _captionFontSize,
                      height: _captionLineHeight / _captionFontSize,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              loading: () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(
                    width: _nameSkeletonWidth,
                    height: _nameSkeletonHeight,
                  ),
                  SizedBox(height: dimens.space1),
                  const SkeletonBox(
                    width: _captionSkeletonWidth,
                    height: _captionSkeletonHeight,
                  ),
                ],
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onToggleFavorite,
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
    );
  }
}
