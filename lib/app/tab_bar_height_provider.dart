import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 하단 탭 바(RootShell.bottomNavigationBar)의 실측 렌더링 높이입니다.
/// RootShell이 GlobalKey로 측정해 갱신하고, 토스트 등 탭 바 위에 겹치지
/// 않게 배치해야 하는 UI가 이 값을 구독합니다.
///
/// 초기값은 실측 전이라 0입니다 — 첫 프레임 이후 곧바로 실제 값으로 갱신됩니다.
final tabBarHeightProvider = NotifierProvider<TabBarHeightNotifier, double>(
  TabBarHeightNotifier.new,
);

class TabBarHeightNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void update(double height) {
    if (state != height) state = height;
  }
}
