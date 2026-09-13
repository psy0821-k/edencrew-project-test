import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme.dart';

// AppDimens에 48px 아이콘 크기 토큰이 없어 Figma 실측값을 로컬 상수로 둔다.
const double _iconSize = 48;
const double _titleFontSize = 19;
const double _titleLineHeight = 22;
const double _titleLetterSpacing = -0.2;
const double _captionFontSize = 11;
const double _captionLineHeight = 14;

/// 아이콘 + 타이틀 + 캡션으로 구성된 공용 빈/안내 상태 뷰.
/// 관심 화면의 빈 상태, 검색 화면의 초기/결과없음 상태가 이 위에서 구성된다.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.caption,
  });

  /// 표시할 SVG 아이콘 asset 경로. 예: `assets/icons/ico_star.svg`
  final String iconAsset;

  /// 굵게 표시되는 제목 문구. 예: `관심 종목이 없습니다`
  final String title;

  /// 제목 아래 보조 설명 문구. 예: `검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.`
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: _iconSize,
            height: _iconSize,
            colorFilter: ColorFilter.mode(colors.textTertiary, BlendMode.srcIn),
          ),
          SizedBox(height: dimens.space4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.bold,
              fontSize: _titleFontSize,
              height: _titleLineHeight / _titleFontSize,
              letterSpacing: _titleLetterSpacing,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: dimens.space4),
          Text(
            caption,
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
