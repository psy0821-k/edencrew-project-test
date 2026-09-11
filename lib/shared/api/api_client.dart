import 'dart:async';

import 'package:http/http.dart' as http;

import '../error/failure.dart';

/// Naver API 4종 호출을 감싸는 단일 HTTP 게이트웨이입니다.
///
/// `dio` 대신 `http`를 채택했습니다 — 이 4개 endpoint는 인증·업로드·스트리밍이
/// 없어 interceptor 같은 부가 기능이 필요하지 않고, 이 클래스로 감싸두면
/// 추후 `dio`로 교체해도 호출부(entities/features)는 영향받지 않습니다.
class ApiClient {
  ApiClient({http.Client? client, this.maxRetries = 3, this.retryDelay = const Duration(milliseconds: 300)})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// 일별 시세 페이지네이션처럼 일부 요청이 실패할 수 있는 경우를 위한 재시도 횟수.
  final int maxRetries;

  /// 재시도 사이의 고정 딜레이. (지수 백오프는 이 규모에 과함)
  final Duration retryDelay;

  /// GET 요청을 보내고 실패 시 [maxRetries]까지 재시도합니다.
  ///
  /// 응답 바이트를 그대로 반환합니다 — 일별 시세 HTML처럼 비UTF-8 인코딩인
  /// 응답을 호출부에서 직접 디코딩할 수 있도록 하기 위함입니다.
  Future<http.Response> get(Uri uri) async {
    Object? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client.get(uri);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        lastError = NetworkFailure('HTTP ${response.statusCode}: $uri');
      } catch (e) {
        lastError = e;
      }

      if (attempt < maxRetries) {
        await Future<void>.delayed(retryDelay);
      }
    }

    throw lastError is Failure ? lastError : NetworkFailure('$lastError');
  }

  void close() => _client.close();
}
