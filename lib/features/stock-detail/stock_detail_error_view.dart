import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';

const double _iconSize = 48;
const double _titleFontSize = 19;
const double _titleLineHeight = 22;
const double _titleLetterSpacing = -0.2;
const double _captionFontSize = 11;
const double _captionLineHeight = 14;
const double _buttonFontSize = 13;
const double _buttonLineHeight = 18;

/// 상세 화면 최초 조회(quote/stockMeta) 실패 시 헤더 아래 영역 전체를
/// 대체하는 에러 뷰. WatchlistErrorView와 동일 패턴, 상세 화면 전용 문구.
class StockDetailErrorView extends StatelessWidget {
  const StockDetailErrorView({super.key, required this.onRetryTap});

  /// "다시 시도" 버튼을 탭했을 때 호출된다.
  final VoidCallback onRetryTap;

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
            'assets/icons/ico_search_empty.svg',
            width: _iconSize,
            height: _iconSize,
            colorFilter: ColorFilter.mode(colors.textTertiary, BlendMode.srcIn),
          ),
          SizedBox(height: dimens.space4),
          Text(
            '종목 정보를 불러오지 못했습니다',
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
            '네트워크 상태를 확인한 뒤\n다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.regular,
              fontSize: _captionFontSize,
              height: _captionLineHeight / _captionFontSize,
              color: colors.textTertiary,
            ),
          ),
          SizedBox(height: dimens.space4),
          OutlinedButton(
            onPressed: onRetryTap,
            child: Text(
              '다시 시도',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: AppTypography.bold,
                fontSize: _buttonFontSize,
                height: _buttonLineHeight / _buttonFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
