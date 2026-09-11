import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'stock_detail_page.dart';

/// 검색 화면. Phase 0에서는 라우팅 스켈레톤 검증용 더미 콘텐츠만 표시합니다.
/// 실제 UI(검색어 입력·결과 목록·빈 상태 등)는 별도 feature에서 구현합니다.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const StockDetailPage(symbol: '000660'),
            ),
          ),
          child: Text(
            '검색 화면 (더미) — 탭하면 상세로 이동',
            style: TextStyle(color: colors.accentDefault),
          ),
        ),
      ),
    );
  }
}
