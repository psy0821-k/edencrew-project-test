import 'package:intl/intl.dart';

/// 숫자를 화면에 표시할 형태로 변환하는 순수 함수 모음입니다.
///
/// `intl`의 `NumberFormat`은 천 단위 콤마는 지원하지만, 이 앱이 요구하는
/// 한국식 억/조 단위 축약 표기(`29,113천`, `1,063조`)는 지원하지 않아 직접 구현합니다.
abstract final class NumberFormatter {
  static final NumberFormat _comma = NumberFormat.decimalPattern('ko_KR');

  /// 천 단위 콤마를 넣습니다. 예: `200000` → `200,000`
  static String comma(num value) => _comma.format(value);

  /// 거래량·시가총액처럼 큰 수를 국내 증권 시세 표기 관행에 맞춰 축약합니다.
  ///
  /// 과제 요구사항의 표기 예시(`29,113천`, `1,063조`)를 따라 **천/조 두 단위만** 사용합니다.
  /// "만/억"은 국내 증권 시세 화면에서 거의 쓰이지 않는 표기라 의도적으로 제외했습니다.
  /// 예: `29113000` → `29,113천`, `1063000000000000` → `1,063조`
  static String compactKorean(num value) {
    final abs = value.abs();

    const jo = 1000000000000; // 조 (10^12)
    const cheon = 1000; // 천

    final (unit, divisor) = switch (abs) {
      >= jo => ('조', jo),
      >= cheon => ('천', cheon),
      _ => ('', 1),
    };

    final scaled = (value / divisor).truncate();
    return unit.isEmpty ? comma(scaled) : '${comma(scaled)}$unit';
  }
}
