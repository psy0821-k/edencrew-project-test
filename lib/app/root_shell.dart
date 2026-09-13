import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../pages/search_page.dart';
import '../pages/watchlist_page.dart';
import '../theme/theme.dart';
import 'current_tab_provider.dart';
import 'tab_bar_height_provider.dart';

const double _navIconSize = 22;

/// 관심/검색 탭을 유지하는 최상위 셸입니다.
///
/// `IndexedStack`을 사용해 탭을 전환해도 각 화면의 상태(스크롤 위치 등)가
/// 유지되도록 하고, 탭 인덱스는 [currentTabProvider]로 관리합니다.
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  final _tabBarKey = GlobalKey();

  void _reportTabBarHeight(Duration _) {
    final height = _tabBarKey.currentContext?.size?.height;
    if (height != null) {
      ref.read(tabBarHeightProvider.notifier).update(height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final colors = context.colors;
    final dimens = context.dimens;

    WidgetsBinding.instance.addPostFrameCallback(_reportTabBarHeight);

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: const [WatchlistPage(), SearchPage()],
      ),
      bottomNavigationBar: Container(
        key: _tabBarKey,
        padding: EdgeInsets.symmetric(vertical: dimens.space2),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border(
            top: BorderSide(
              width: dimens.borderHairline,
              color: colors.borderSubtle,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) =>
              ref.read(currentTabProvider.notifier).select(index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: colors.navActive,
          unselectedItemColor: colors.navInactive,
          selectedLabelStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.regular,
            fontSize: 11,
            height: 14 / 11,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.regular,
            fontSize: 11,
            height: 14 / 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/ico_star.svg',
                  width: _navIconSize,
                  height: _navIconSize,
                  colorFilter:
                      ColorFilter.mode(colors.navInactive, BlendMode.srcIn),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/ico_star_filled.svg',
                  width: _navIconSize,
                  height: _navIconSize,
                  colorFilter:
                      ColorFilter.mode(colors.navActive, BlendMode.srcIn),
                ),
              ),
              label: '관심',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/ico_search.svg',
                  width: _navIconSize,
                  height: _navIconSize,
                  colorFilter:
                      ColorFilter.mode(colors.navInactive, BlendMode.srcIn),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: SvgPicture.asset(
                  'assets/icons/ico_search.svg',
                  width: _navIconSize,
                  height: _navIconSize,
                  colorFilter:
                      ColorFilter.mode(colors.navActive, BlendMode.srcIn),
                ),
              ),
              label: '검색',
            ),
          ],
        ),
      ),
    );
  }
}
