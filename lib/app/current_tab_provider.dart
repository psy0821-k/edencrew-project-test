import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 하단 탭 바에서 현재 선택된 탭의 인덱스입니다. (0 = 관심, 1 = 검색)
final currentTabProvider = NotifierProvider<CurrentTabNotifier, int>(
  CurrentTabNotifier.new,
);

class CurrentTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}
