import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/search_page.dart';
import '../pages/watchlist_page.dart';
import '../theme/theme.dart';
import 'current_tab_provider.dart';

/// 관심/검색 탭을 유지하는 최상위 셸입니다.
///
/// `IndexedStack`을 사용해 탭을 전환해도 각 화면의 상태(스크롤 위치 등)가
/// 유지되도록 하고, 탭 인덱스는 [currentTabProvider]로 관리합니다.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final colors = context.colors;

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: const [WatchlistPage(), SearchPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) => ref.read(currentTabProvider.notifier).select(index),
        selectedItemColor: colors.navActive,
        unselectedItemColor: colors.navInactive,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '관심'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
        ],
      ),
    );
  }
}
