import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/daily_quote/daily_quote_providers.dart';
import '../../entities/daily_quote/period.dart';
import '../../theme/theme.dart';

const double _tabHeight = 28;
const double _tabPaddingHorizontal = 12;
const double _tabPaddingVertical = 5;
const double _tabGap = 4;
const double _tabFontSize = 13;
const double _tabLineHeight = 18;

/// 1개월/3개월/6개월/1년 탭. 선택된 탭은 accentDefault(텍스트)/accentBg(배경).
class StockDetailPeriodTabs extends ConsumerWidget {
  const StockDetailPeriodTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dimens = context.dimens;
    final selected = ref.watch(selectedPeriodProvider);

    return Row(
      children: [
        for (final period in Period.values) ...[
          if (period != Period.values.first) const SizedBox(width: _tabGap),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(selectedPeriodProvider.notifier).state = period,
              child: Container(
                height: _tabHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: _tabPaddingHorizontal,
                  vertical: _tabPaddingVertical,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: period == selected ? colors.accentBg : null,
                  borderRadius: BorderRadius.circular(dimens.radiusSm),
                ),
                child: Text(
                  period.label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontWeight: AppTypography.regular,
                    fontSize: _tabFontSize,
                    height: _tabLineHeight / _tabFontSize,
                    color: period == selected
                        ? colors.accentDefault
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
