import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  // 🚀 플랫폼에 따라 자동으로 서버 주소 선택
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';  // Android 에뮬레이터
    } else if (Platform.isIOS) {
      return 'http://localhost:8080';  // iOS 시뮬레이터
    } else if (Platform.isMacOS) {
      return 'http://localhost:8080';  // macOS
    } else {
      return 'http://localhost:8080';  // 기본값
    }
  }

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // 🔧 OAuth 로그인 요청
  static Future<Map<String, dynamic>?> sendOAuthLogin({
    required String provider,
    required String accessToken,
  }) async {
    try {
      print('🔍 서버로 토큰 전송 시작 - Provider: $provider');
      print('🔍 서버 주소: $baseUrl');

      final response = await _dio.post(
        '/oauth/login',
        data: {
          'provider': provider,
          'accessToken': accessToken,
        },
      );

      print('✅ 서버 응답 성공 - 상태코드: ${response.statusCode}');
      print('✅ 서버 응답 데이터: ${response.data}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print('❌ 네트워크 오류: ${e.type}');
      print('❌ 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('❌ 서버 응답 코드: ${e.response?.statusCode}');
        print('❌ 서버 응답 데이터: ${e.response?.data}');
      }

      return {
        'success': false,
        'error': e.message,
        'type': e.type.toString(),
      };
    } catch (e) {
      print('❌ 서버 전송 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}