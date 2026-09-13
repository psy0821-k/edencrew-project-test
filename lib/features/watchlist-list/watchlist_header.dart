import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';

/// 관심 화면 상단 헤더.
/// `AppDimens`에 헤더 높이·폰트 크기·행간 토큰이 없어 Figma 실측값을 로컬 상수로 둔다.
const double _headerHeight = 52;
const double _featureFontSize = 13;
const double _titleFontSize = 19;
const double _titleLineHeight = 22;
const double _titleLetterSpacing = -0.2;

class WatchlistHeader extends StatelessWidget {
  const WatchlistHeader({
    super.key,
    required this.sortLabel,
    required this.onSortTap,
    required this.onRefreshTap,
  });

  /// 정렬 칩에 표시할 현재 정렬 기준 라벨. 예: `가나다순`
  final String sortLabel;

  /// 정렬 칩을 탭했을 때 호출된다. (정렬 바텀시트를 여는 동작은 상위에서 구현)
  final VoidCallback onSortTap;

  /// 새로고침 버튼을 탭했을 때 호출된다. (시세 재조회는 상위에서 구현)
  final VoidCallback onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return SizedBox(
      width: double.infinity,
      height: _headerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '관심',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: AppTypography.bold,
                fontSize: _titleFontSize,
                height: _titleLineHeight / _titleFontSize,
                letterSpacing: _titleLetterSpacing,
                color: colors.textPrimary,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onSortTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        sortLabel,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: AppTypography.bold,
                          fontSize: _featureFontSize,
                          height: _titleLineHeight / _featureFontSize,
                          color: colors.textSecondary,
                        ),
                      ),
                      SvgPicture.asset('assets/icons/ico_align.svg'),
                    ],
                  ),
                ),
                SizedBox(width: dimens.space4),
                IconButton(
                  onPressed: onRefreshTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: SvgPicture.asset('assets/icons/ico_refresh.svg'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
