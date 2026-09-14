import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart' as cp949_pkg;

/// `finance.naver.com/item/sise_day.naver` 응답이 사용하는 EUC-KR 인코딩을
/// 디코딩합니다.
///
/// `dart:convert`는 EUC-KR을 기본 지원하지 않습니다. EUC-KR 완성형 한글
/// (KS X 1001) 2,350자는 초성·중성·종성 산술 공식만으로 유니코드에 매핑되지
/// 않아(자주 쓰는 조합만 골라 자체 순서를 매긴 서브셋), 완전한 매핑 표가
/// 필요합니다. `cp949_codec` 패키지(CP949는 EUC-KR의 상위 호환)가 이 표를
/// 이미 내장하고 있어 이를 사용합니다.
final Encoding eucKr = cp949_pkg.cp949;
