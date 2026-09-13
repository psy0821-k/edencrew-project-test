import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'skeleton_box.dart';

const double _nameSkeletonWidth = 120;
const double _nameSkeletonHeight = 20;
const double _metaSkeletonWidth = 80;
const double _metaSkeletonHeight = 14;

/// 검색 결과 로딩 중 표시하는 스켈레톤 행 하나.
/// SearchResultRow와 동일한 레이아웃(패딩, border-bottom, 좌측 텍스트 자리,
/// 우측 별 아이콘 자리)을 실제 데이터 없이 SkeletonBox로만 채운다.
class SearchResultSkeletonRow extends StatelessWidget {
  const SearchResultSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                  width: _nameSkeletonWidth,
                  height: _nameSkeletonHeight,
                ),
                const SizedBox(height: 2),
                const SkeletonBox(
                  width: _metaSkeletonWidth,
                  height: _metaSkeletonHeight,
                ),
              ],
            ),
          ),
          SizedBox(width: dimens.space2),
          SkeletonBox(width: dimens.iconMd, height: dimens.iconMd),
        ],
      ),
    );
  }
}
