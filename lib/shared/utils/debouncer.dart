import 'dart:async';

/// 짧은 시간 안에 반복 호출되는 동작을 마지막 호출만 실행되도록 지연시킵니다.
///
/// 검색어 입력처럼 매 타이핑마다 API를 호출하지 않고, 입력이 멈춘 뒤에만
/// 실제 동작을 실행하고 싶을 때 사용합니다.
///
/// ```dart
/// final debouncer = Debouncer(const Duration(milliseconds: 300));
///
/// void onSearchChanged(String query) {
///   debouncer.run(() => ref.read(searchProvider.notifier).search(query));
/// }
/// ```
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  /// [action]을 [delay] 이후에 실행합니다.
  /// 이 메서드가 다시 호출되면 이전에 예약된 실행은 취소됩니다.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 예약된 실행을 취소하고 타이머를 정리합니다.
  /// 위젯의 `dispose()`에서 반드시 호출해야 메모리 누수를 막을 수 있습니다.
  void dispose() {
    _timer?.cancel();
  }
}
