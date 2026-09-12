import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';

const double _starIconSize = 48;
const double _titleFontSize = 19;
const double _titleLineHeight = 22;
const double _titleLetterSpacing = -0.2;
const double _captionFontSize = 11;
const double _captionLineHeight = 14;
const double _gap = 16;

/// 관심종목이 하나도 없을 때 보여주는 빈 상태 뷰. (`01 · 관심_empty`)
class WatchlistEmptyView extends StatelessWidget {
  const WatchlistEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/ico_star.svg',
            width: _starIconSize,
            height: _starIconSize,
            colorFilter: ColorFilter.mode(colors.textTertiary, BlendMode.srcIn),
          ),
          const SizedBox(height: _gap),
          Text(
            '관심 종목이 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.bold,
              fontSize: _titleFontSize,
              height: _titleLineHeight / _titleFontSize,
              letterSpacing: _titleLetterSpacing,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: _gap),
          Text(
            '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.regular,
              fontSize: _captionFontSize,
              height: _captionLineHeight / _captionFontSize,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
