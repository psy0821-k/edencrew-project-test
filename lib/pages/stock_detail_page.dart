import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/quote/quote.dart';
import '../entities/quote/quote_providers.dart';
import '../entities/stock_meta/stock_meta.dart';
import '../entities/stock_meta/stock_meta_providers.dart';
import '../features/stock-detail/stock_detail_candle_chart.dart';
import '../features/stock-detail/stock_detail_daily_quote_notifier.dart';
import '../features/stock-detail/stock_detail_daily_quote_table.dart';
import '../features/stock-detail/stock_detail_error_view.dart';
import '../features/stock-detail/stock_detail_header.dart';
import '../features/stock-detail/stock_detail_period_error_banner.dart';
import '../features/stock-detail/stock_detail_period_tabs.dart';
import '../features/stock-detail/stock_detail_price_section.dart';
import '../features/stock-detail/stock_detail_summary_card.dart';
import '../theme/theme.dart';

/// 종목 상세 화면. 헤더(뒤로가기/종목명/종목코드·시장/관심 버튼) + 현재가·등락 +
/// 기간 탭/요약 카드/캔들 차트/일별 시세 표를 표시한다.
class StockDetailPage extends ConsumerWidget {
  const StockDetailPage({required this.symbol, super.key});

  /// 종목 코드 (6자리). 검색/관심 화면에서 탭한 종목을 식별합니다.
  final String symbol;

  void _onRetryTap(WidgetRef ref) {
    ref.invalidate(quoteProvider(symbol));
    ref.invalidate(stockMetaProvider(symbol));
  }

  void _onPeriodRetryTap(WidgetRef ref) {
    ref.invalidate(stockDetailDailyQuoteProvider(symbol));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(quoteProvider(symbol));
    final stockMeta = ref.watch(stockMetaProvider(symbol));
    final dailyQuoteState = ref.watch(stockDetailDailyQuoteProvider(symbol));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StockDetailHeader(symbol: symbol, stockMeta: stockMeta),
            Expanded(
              child: _buildBody(context, ref, quote, stockMeta, dailyQuoteState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Quote> quote,
    AsyncValue<StockMeta> stockMeta,
    StockDetailDailyQuoteState dailyQuoteState,
  ) {
    final dimens = context.dimens;

    if (quote.hasError || stockMeta.hasError) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: StockDetailErrorView(onRetryTap: () => _onRetryTap(ref)),
      );
    }

    final dailyQuotes = dailyQuoteState.quotes;
    final isInitialLoading =
        !quote.hasValue || !stockMeta.hasValue || dailyQuotes == null;
    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StockDetailPriceSection(quote: quote.requireValue),
          SizedBox(height: dimens.space4),
          const StockDetailPeriodTabs(),
          SizedBox(height: dimens.space4),
          if (dailyQuoteState.error != null)
            StockDetailPeriodErrorBanner(
              onRetryTap: () => _onPeriodRetryTap(ref),
            ),
          StockDetailCandleChart(quotes: dailyQuotes),
          SizedBox(height: dimens.space4),
          StockDetailSummaryCard(
            latestDailyQuote: dailyQuotes.first,
            marketCap: quote.requireValue.marketCap,
          ),
          SizedBox(height: dimens.space6),
          StockDetailDailyQuoteTable(quotes: dailyQuotes),
        ],
      ),
    );
  }
}
