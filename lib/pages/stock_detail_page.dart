import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/quote/quote_providers.dart';
import '../entities/stock_meta/stock_meta_providers.dart';
import '../features/stock-detail/stock_detail_error_view.dart';
import '../features/stock-detail/stock_detail_header.dart';
import '../features/stock-detail/stock_detail_price_section.dart';
import '../theme/theme.dart';
import '../widgets/skeleton_box.dart';

const double _bodySkeletonHeight = 120;

/// 종목 상세 화면. 헤더(뒤로가기/종목명/종목코드·시장/관심 버튼) +
/// 현재가·등락을 표시한다. 기간 탭/차트/표는 이슈 #57 이후 범위.
class StockDetailPage extends ConsumerWidget {
  const StockDetailPage({required this.symbol, super.key});

  /// 종목 코드 (6자리). 검색/관심 화면에서 탭한 종목을 식별합니다.
  final String symbol;

  void _onRetryTap(WidgetRef ref) {
    ref.invalidate(quoteProvider(symbol));
    ref.invalidate(stockMetaProvider(symbol));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimens = context.dimens;
    final quote = ref.watch(quoteProvider(symbol));
    final stockMeta = ref.watch(stockMetaProvider(symbol));
    final hasError = quote.hasError || stockMeta.hasError;
    final hasData = quote.hasValue && stockMeta.hasValue;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StockDetailHeader(symbol: symbol, stockMeta: stockMeta),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dimens.space4),
                child: hasError
                    ? StockDetailErrorView(onRetryTap: () => _onRetryTap(ref))
                    : hasData
                    ? StockDetailPriceSection(quote: quote.requireValue)
                    : const SkeletonBox(
                        width: double.infinity,
                        height: _bodySkeletonHeight,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
