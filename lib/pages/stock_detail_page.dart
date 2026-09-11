import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// 종목 상세 화면. Phase 0에서는 라우팅 스켈레톤 검증용 더미 콘텐츠만 표시합니다.
/// 실제 UI(현재가·차트·일별 시세 표 등)는 별도 feature에서 구현합니다.
class StockDetailPage extends StatelessWidget {
  const StockDetailPage({required this.symbol, super.key});

  /// 종목 코드 (6자리). 검색/관심 화면에서 탭한 종목을 식별합니다.
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text('종목상세 · $symbol')),
      body: Center(
        child: Text(
          '상세 화면 (더미) — symbol: $symbol',
          style: TextStyle(color: colors.textPrimary),
        ),
      ),
    );
  }
}
