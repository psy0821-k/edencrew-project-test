import 'package:edencrew_assignment_starter/shared/utils/euc_kr_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EucKrCodec', () {
    test("실측 확인된 EUC-KR 바이트(0xB0 0xA1)를 디코딩하면 '가'를 반환한다", () {
      final decoded = eucKr.decode([0xB0, 0xA1]);

      expect(decoded, '가');
    });

    test('실제 응답에 등장하는 여러 글자를 포함한 바이트 시퀀스를 디코딩하면 원문과 일치한다', () {
      // '날짜' = b3af c2a5 (EUC-KR)
      final decoded = eucKr.decode([0xB3, 0xAF, 0xC2, 0xA5]);

      expect(decoded, '날짜');
    });

    test('ASCII 문자(영문/숫자/기호)가 섞인 바이트를 디코딩하면 그대로 유지된다', () {
      // 'A1,2 a' 는 전부 ASCII 범위(0x00~0x7F)
      final bytes = 'A1,2 a'.codeUnits;

      final decoded = eucKr.decode(bytes);

      expect(decoded, 'A1,2 a');
    });

    test('매핑 테이블에 없는 EUC-KR 바이트 조합을 디코딩하면 FormatException을 던진다', () {
      // 0xFF 0xFF 는 매핑 테이블에 존재하지 않는 조합
      expect(() => eucKr.decode([0xFF, 0xFF]), throwsFormatException);
    });

    test('기존 40자 매핑 테이블에 없던 완성형 한글(삼성전자)을 디코딩하면 원문과 일치한다', () {
      // '삼성전자' = bbef bcba c0fc c0da (EUC-KR) — 기존 하드코딩 표에 없던 글자들
      final decoded = eucKr.decode([
        0xBB, 0xEF, 0xBC, 0xBA, 0xC0, 0xFC, 0xC0, 0xDA,
      ]);

      expect(decoded, '삼성전자');
    });
  });
}
