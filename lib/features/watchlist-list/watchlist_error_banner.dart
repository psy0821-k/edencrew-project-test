import 'package:flutter/material.dart';

import '../../theme/theme.dart';

const double _fontSize = 12;
const double _lineHeight = 16;

/// 이전에 성공적으로 표시한 목록이 있는 상태에서 재조회가 실패했을 때,
/// 목록은 유지한 채 상단에 노출하는 얇은 경고 배너. (`01 · 관심` 화면)
class WatchlistErrorBanner extends StatelessWidget {
  const WatchlistErrorBanner({super.key, required this.onRetryTap});

  /// "다시 시도" 텍스트를 탭했을 때 호출된다.
  final VoidCallback onRetryTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: dimens.space2,
        horizontal: dimens.space4,
      ),
      color: colors.feedbackWarning,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '목록을 불러오지 못했습니다',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: AppTypography.medium,
                fontSize: _fontSize,
                height: _lineHeight / _fontSize,
                color: colors.surfaceBase,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetryTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '다시 시도',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: AppTypography.bold,
                fontSize: _fontSize,
                height: _lineHeight / _fontSize,
                color: colors.surfaceBase,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
