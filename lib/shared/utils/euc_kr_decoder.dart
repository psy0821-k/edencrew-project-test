import 'dart:convert';

/// `finance.naver.com/item/sise_day.naver` 응답이 사용하는 EUC-KR 인코딩을
/// 디코딩합니다.
///
/// `dart:convert`는 EUC-KR을 기본 지원하지 않고, 완성형 한글 2,350자 전체를
/// 매핑하는 것은 이 과제 범위를 넘는 과한 작업이라 판단해, **실제 일별 시세
/// 응답 HTML(1·2페이지 실측)에 등장하는 문자(날짜/숫자/상승·하락·보합/
/// 맨앞·맨뒤 등 40자)만 담은 매핑 테이블**을 직접 만들었습니다. 매핑에 없는
/// 바이트 조합은 [FormatException]을 던져, 알 수 없는 문자를 조용히
/// 깨뜨리지 않습니다.
final eucKr = const _EucKrCodec();

class _EucKrCodec extends Encoding {
  const _EucKrCodec();

  @override
  String get name => 'euc-kr';

  @override
  Converter<List<int>, String> get decoder => const _EucKrDecoder();

  @override
  Converter<String, List<int>> get encoder =>
      throw UnsupportedError('EucKrCodec은 디코딩만 지원합니다.');
}

class _EucKrDecoder extends Converter<List<int>, String> {
  const _EucKrDecoder();

  /// `(첫 바이트 << 8) | 두 번째 바이트` → 유니코드 코드포인트.
  /// 실측한 39개 한글 문자만 담은 완성형 EUC-KR 매핑 테이블.
  static const Map<int, int> _table = {
    45217: 44032, // 가
    45253: 44144, // 거
    45268: 44172, // 게
    45293: 44256, // 고
    45511: 44428, // 권
    48853: 50526, // 앞
    45985: 45149, // 끝
    45999: 45216, // 날
    46039: 45348, // 네
    46297: 45796, // 다
    46554: 46244, // 뒤
    46836: 46973, // 락
    47009: 47000, // 래
    47022: 47049, // 량
    47278: 47532, // 리
    47303: 47592, // 맨
    47792: 48324, // 별
    47800: 48372, // 보
    47857: 48708, // 비
    48115: 49345, // 상
    48316: 49464, // 세
    48327: 49496, // 션
    48570: 49828, // 스
    48578: 49849, // 승
    48579: 49884, // 시
    49341: 51020, // 음
    49356: 51060, // 이
    49359: 51068, // 일
    49371: 51089, // 작
    49402: 51200, // 저
    49404: 51204, // 전
    49598: 51333, // 종
    49653: 51613, // 증
    49654: 51648, // 지
    49829: 51676, // 짜
    50862: 53944, // 트
    50916: 54168, // 페
    51151: 54616, // 하
    51157: 54633, // 합
  };

  @override
  String convert(List<int> input) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < input.length) {
      final byte = input[i];
      if (byte < 0x80) {
        // ASCII 범위(영문/숫자/기호)는 1바이트 그대로 사용.
        buffer.writeCharCode(byte);
        i++;
        continue;
      }
      if (i + 1 >= input.length) {
        throw FormatException('EUC-KR 2바이트 문자가 잘렸습니다.', input, i);
      }
      final key = (byte << 8) | input[i + 1];
      final codePoint = _table[key];
      if (codePoint == null) {
        throw FormatException(
          '매핑 테이블에 없는 EUC-KR 바이트 조합입니다: 0x${key.toRadixString(16)}',
          input,
          i,
        );
      }
      buffer.writeCharCode(codePoint);
      i += 2;
    }
    return buffer.toString();
  }
}
