import 'package:flutter/material.dart';

import '../theme/theme.dart';

const Duration _pulseDuration = Duration(milliseconds: 900);
const double _minOpacity = 0.4;
const double _maxOpacity = 1;

/// 로딩 중인 값의 자리를 표시하는 네모박스. 배경이 밝아졌다 어두워지는
/// pulse 애니메이션을 반복한다. 관심/검색/상세 화면이 공유하는 도메인 비종속 위젯.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _pulseDuration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity =
            _minOpacity + (_maxOpacity - _minOpacity) * _controller.value;
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.feedbackSkeleton,
          borderRadius: BorderRadius.circular(dimens.radiusSm),
        ),
      ),
    );
  }
}
