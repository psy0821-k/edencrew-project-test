import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import 'sort_criteria.dart';
import 'watchlist_sort_provider.dart';

const double _sheetWidth = 393;
const double _sheetPaddingTop = 1;
const double _sheetPaddingBottom = 34;
const double _sheetRadius = 16;
const double _titleFontSize = 19;
const double _titleLineHeight = 22;
const double _titleLetterSpacing = -0.2;
const double _optionFontSize = 15;
const double _optionLineHeight = 20;
const double _optionLetterSpacing = -0.1;
const double _optionVerticalPadding = 18;
const double _titleVerticalPadding = 21;

/// 관심 화면 정렬 기준을 고르는 바텀시트. (`01 · 관심_sort`)
///
/// 항목을 탭하면 [watchlistSortCriteriaProvider]에 즉시 반영하고 시트를 닫는다.
void showWatchlistSortSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => const _WatchlistSortSheetContent(),
  );
}

class _WatchlistSortSheetContent extends ConsumerWidget {
  const _WatchlistSortSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selected = ref.watch(watchlistSortCriteriaProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: _sheetWidth,
        padding: const EdgeInsets.only(
          top: _sheetPaddingTop,
          bottom: _sheetPaddingBottom,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceOverlay,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_sheetRadius),
            topRight: Radius.circular(_sheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: _titleVerticalPadding,
              ),
              child: Text(
                '정렬',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: AppTypography.bold,
                  fontSize: _titleFontSize,
                  height: _titleLineHeight / _titleFontSize,
                  letterSpacing: _titleLetterSpacing,
                  color: colors.textPrimary,
                ),
              ),
            ),
            for (final criteria in SortCriteria.values)
              _SortOptionTile(
                criteria: criteria,
                selected: criteria == selected,
                onTap: () {
                  ref.read(watchlistSortCriteriaProvider.notifier).state =
                      criteria;
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.criteria,
    required this.selected,
    required this.onTap,
  });

  final SortCriteria criteria;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.textPrimary : colors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: _optionVerticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              criteria.label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: AppTypography.medium,
                fontSize: _optionFontSize,
                height: _optionLineHeight / _optionFontSize,
                letterSpacing: _optionLetterSpacing,
                color: color,
              ),
            ),
            if (selected) Icon(Icons.check, color: color),
          ],
        ),
      ),
    );
  }
}
