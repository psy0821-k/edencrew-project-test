import 'package:flutter/material.dart';

import '../../widgets/empty_state_view.dart';

/// 관심종목이 하나도 없을 때 보여주는 빈 상태 뷰. (`01 · 관심_empty`)
class WatchlistEmptyView extends StatelessWidget {
  const WatchlistEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateView(
      iconAsset: 'assets/icons/ico_star.svg',
      title: '관심 종목이 없습니다',
      caption: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
    );
  }
}
