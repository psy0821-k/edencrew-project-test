import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';

const double _fontSize = 15;
const double _lineHeight = 20;
// AppDimens에 검색 입력창 높이 토큰이 없어 Figma 실측값을 로컬 상수로 둔다.
const double _fieldHeight = 40;

/// 검색 입력창 + 우측 지우기(X) 버튼.
class SearchInputField extends StatelessWidget {
  const SearchInputField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;

  /// 텍스트가 바뀔 때마다 호출한다. (원본 문자열 그대로 전달 — 정규화는 상위에서)
  final ValueChanged<String> onChanged;

  /// X 버튼을 탭했을 때 호출한다. (controller.clear()와 상태 초기화는 호출부 책임)
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      height: _fieldHeight,
      padding: EdgeInsets.symmetric(horizontal: dimens.space3),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
        border: Border.all(
          color: colors.borderStrong,
          width: dimens.borderHairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/ico_search.svg',
            width: dimens.iconSm,
            height: dimens.iconSm,
            colorFilter: ColorFilter.mode(colors.textTertiary, BlendMode.srcIn),
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: AppTypography.regular,
                  fontSize: _fontSize,
                  height: _lineHeight / _fontSize,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '종목명 또는 종목코드',
                  hintStyle: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontWeight: AppTypography.regular,
                    fontSize: _fontSize,
                    height: _lineHeight / _fontSize,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: dimens.space2),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.clear, size: dimens.iconSm, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
