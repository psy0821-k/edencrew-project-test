import 'package:flutter/material.dart';

import '../../theme/theme.dart';

const double _fontSize = 15;
const double _lineHeight = 20;
const double _horizontalPadding = 16;
const double _verticalPadding = 12;

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

    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.regular,
          fontSize: _fontSize,
          height: _lineHeight / _fontSize,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '종목명 또는 종목코드',
          hintStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.regular,
            fontSize: _fontSize,
            height: _lineHeight / _fontSize,
            color: colors.textTertiary,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: _verticalPadding,
          ),
        ),
      ),
    );
  }
}
