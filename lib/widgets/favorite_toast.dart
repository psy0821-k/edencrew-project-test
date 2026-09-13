import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/tab_bar_height_provider.dart';
import '../theme/theme.dart';

// Figma 실측값. AppDimens에 토스트 박스 크기 토큰이 없어 로컬 상수로 둔다.
const double _toastWidth = 361;
const double _toastHorizontalPadding = 16;
const double _toastVerticalPadding = 14;
const double _toastTextFontSize = 13;
const double _toastTextLineHeight = 18;
const double _bottomGapFromFooter = 12;

// 등장(슬라이드+페이드)/퇴장(페이드) 애니메이션 지속 시간.
// 짧은 확인용 토스트라 화려한 연출 대신 최소한의 자연스러움만 준다.
const Duration _enterDuration = Duration(milliseconds: 200);
const Duration _exitDuration = Duration(milliseconds: 150);
const Duration _visibleDuration = Duration(seconds: 2);

OverlayEntry? _currentToastEntry;
_FavoriteToastOverlayState? _currentToastState;
Timer? _currentToastTimer;

/// 관심 등록/해제 토스트를 화면 하단(탭바 위 12px)에 표시한다.
/// 이미 떠 있는 토스트가 있으면 즉시 제거하고 새 토스트로 교체한다.
/// 등장(슬라이드+페이드) 후 2초 뒤 퇴장(페이드)하며 사라진다.
///
/// 반환하는 [Timer]는 호출부가 들고 있다가, 위젯이 dispose되기 전에
/// `cancel()`해야 한다(그렇지 않으면 위젯 트리 밖에서 살아남아
/// "타이머가 남아있다"는 테스트 실패나 dispose 후 접근 문제로 이어진다).
Timer showFavoriteToast(BuildContext context, bool isNowFavorite) {
  _currentToastEntry?.remove();
  _currentToastTimer?.cancel();

  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _FavoriteToastOverlay(
      isNowFavorite: isNowFavorite,
      onStateReady: (state) => _currentToastState = state,
    ),
  );
  _currentToastEntry = entry;
  overlay.insert(entry);

  final timer = Timer(_visibleDuration, () {
    _dismissCurrentToast(entry);
  });
  _currentToastTimer = timer;
  return timer;
}

Future<void> _dismissCurrentToast(OverlayEntry entry) async {
  await _currentToastState?.playExit();
  entry.remove();
  if (_currentToastEntry == entry) {
    _currentToastEntry = null;
    _currentToastState = null;
  }
}

class _FavoriteToastOverlay extends StatefulWidget {
  const _FavoriteToastOverlay({
    required this.isNowFavorite,
    required this.onStateReady,
  });

  final bool isNowFavorite;
  final ValueChanged<_FavoriteToastOverlayState> onStateReady;

  @override
  State<_FavoriteToastOverlay> createState() => _FavoriteToastOverlayState();
}

class _FavoriteToastOverlayState extends State<_FavoriteToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _enterDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    widget.onStateReady(this);
  }

  /// 퇴장(페이드아웃) 애니메이션을 재생하고 끝날 때까지 기다린다.
  Future<void> playExit() async {
    await _controller.animateBack(
      0,
      duration: _exitDuration,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final tabBarHeight = ProviderScope.containerOf(
      context,
    ).read(tabBarHeightProvider);

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset + tabBarHeight + _bottomGapFromFooter,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: _FavoriteToastBox(isNowFavorite: widget.isNowFavorite),
          ),
        ),
      ),
    );
  }
}

class _FavoriteToastBox extends StatelessWidget {
  const _FavoriteToastBox({required this.isNowFavorite});

  final bool isNowFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      width: _toastWidth,
      padding: EdgeInsets.symmetric(
        horizontal: _toastHorizontalPadding,
        vertical: _toastVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
        border: Border.all(
          width: dimens.borderHairline,
          color: colors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isNowFavorite
                ? 'assets/icons/ico_star_filled.svg'
                : 'assets/icons/ico_star.svg',
            width: _toastTextLineHeight,
            height: _toastTextLineHeight,
            colorFilter: ColorFilter.mode(
              isNowFavorite ? colors.favoriteActive : colors.textSecondary,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: dimens.space2),
          Text(
            isNowFavorite ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.bold,
              fontSize: _toastTextFontSize,
              height: _toastTextLineHeight / _toastTextFontSize,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
