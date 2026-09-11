import 'package:intl/intl.dart';

/// 날짜를 화면 표기 형태로 변환하거나, Naver 응답의 날짜 문자열을 파싱하는
/// 순수 함수 모음입니다.
///
/// 앱 내부에서는 날짜를 `yyyyMMdd` 문자열로 정규화해 다루고,
/// 화면에는 `MM.dd` 형태로 표시합니다.
///
/// `yyyyMMdd`처럼 구분자 없는 연속 숫자 패턴은 `intl`의 `DateFormat.parse`가
/// 안정적으로 파싱하지 못해(자릿수를 탐욕적으로 소비하다 실패), 파싱은 직접
/// substring으로 처리하고 포맷팅에만 `intl`을 사용합니다.
abstract final class DateFormatter {
  static final DateFormat _display = DateFormat('MM.dd');

  /// `yyyyMMdd` 형태의 문자열을 [DateTime]으로 파싱합니다.
  /// 예: `'20260911'` → `DateTime(2026, 9, 11)`
  static DateTime parseInternal(String yyyyMMdd) {
    if (yyyyMMdd.length != 8) {
      throw FormatException('yyyyMMdd 형식(8자리)이 아닙니다: $yyyyMMdd');
    }
    final year = int.parse(yyyyMMdd.substring(0, 4));
    final month = int.parse(yyyyMMdd.substring(4, 6));
    final day = int.parse(yyyyMMdd.substring(6, 8));
    return DateTime(year, month, day);
  }

  /// [DateTime]을 화면 표시용 `MM.dd` 문자열로 변환합니다.
  /// 예: `DateTime(2026, 9, 11)` → `'09.11'`
  static String toDisplay(DateTime date) => _display.format(date);

  /// `yyyyMMdd` 문자열을 곧바로 화면 표시용 `MM.dd` 문자열로 변환합니다.
  /// 예: `'20260911'` → `'09.11'`
  static String internalToDisplay(String yyyyMMdd) =>
      toDisplay(parseInternal(yyyyMMdd));
}
