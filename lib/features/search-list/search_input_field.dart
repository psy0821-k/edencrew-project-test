import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';

const double _fontSize = 15;
const double _lineHeight = 20;
const double _fieldHeight = 40;
const double _horizontalPadding = 12;
const double _iconGap = 8;
const double _iconSize = 16;
const double _borderRadius = 12;
const double _borderWidth = 1;

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

    return Container(
      height: _fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: colors.borderStrong, width: _borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/ico_search.svg',
            width: _iconSize,
            height: _iconSize,
            colorFilter: ColorFilter.mode(colors.textTertiary, BlendMode.srcIn),
          ),
          const SizedBox(width: _iconGap),
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
          const SizedBox(width: _iconGap),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.clear, size: _iconSize, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
