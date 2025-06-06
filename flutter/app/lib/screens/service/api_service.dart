import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  // 🚀 플랫폼에 따라 자동으로 서버 주소 선택
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // Android 에뮬레이터
    } else if (Platform.isIOS) {
      return 'http://localhost:8080'; // iOS 시뮬레이터
    } else if (Platform.isMacOS) {
      return 'http://localhost:8080'; // macOS
    } else {
      return 'http://localhost:8080'; // 기본값
    }
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // 🔧 OAuth 로그인 요청 (하나만 남김)
  static Future<Map<String, dynamic>?> sendOAuthLogin({
    required String provider,
    required String accessToken,
  }) async {
    try {
      print('🔍 서버로 토큰 전송 시작 - Provider: $provider');
      print('🔍 서버 주소: $baseUrl');

      final response = await _dio.post(
        '/oauth/login',
        data: {'provider': provider, 'accessToken': accessToken},
      );

      print('✅ 서버 응답 성공 - 상태코드: ${response.statusCode}');
      print('✅ 서버 응답 데이터: ${response.data}');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      print('❌ 네트워크 오류: ${e.type}');
      print('❌ 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('❌ 서버 응답 코드: ${e.response?.statusCode}');
        print('❌ 서버 응답 데이터: ${e.response?.data}');
      }

      return {'success': false, 'error': e.message, 'type': e.type.toString()};
    } catch (e) {
      print('❌ 서버 전송 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 🎨 색칠공부 템플릿 목록 조회 (더 자세한 디버깅 추가)
  static Future<List<Map<String, dynamic>>?> getColoringTemplates({
    int page = 0,
    int size = 20,
  }) async {
    try {
      print('🔍 색칠공부 템플릿 조회 시작');
      print('🔍 서버 주소: $baseUrl');
      print('🔍 전체 URL: $baseUrl/api/coloring/templates?page=$page&size=$size');

      final response = await _dio.get(
        '/api/coloring/templates',
        queryParameters: {'page': page, 'size': size},
      );

      print('✅ 응답 상태코드: ${response.statusCode}');
      print('✅ 응답 헤더: ${response.headers}');
      print('✅ 응답 데이터 타입: ${response.data.runtimeType}');
      print('✅ 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 🎯 응답 구조 확인
        if (responseData is Map && responseData['success'] == true) {
          final List<dynamic> templatesJson = responseData['templates'] ?? [];

          final templates =
              templatesJson
                  .map((json) => Map<String, dynamic>.from(json))
                  .toList();

          print('✅ 색칠공부 템플릿 ${templates.length}개 조회 성공');
          return templates;
        } else {
          print('❌ 예상과 다른 응답 구조: $responseData');

          // 🎯 만약 응답이 배열이라면 직접 반환
          if (responseData is List) {
            final templates =
                responseData
                    .map((json) => Map<String, dynamic>.from(json))
                    .toList();
            print('✅ 직접 배열로 받은 템플릿 ${templates.length}개');
            return templates;
          }
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ 네트워크 오류 상세:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');
        print('  - 서버 응답 헤더: ${e.response?.headers}');
      } else {
        print('  - 네트워크 연결 오류 (서버가 꺼져있거나 주소가 잘못됨)');
      }
    } catch (e) {
      print('❌ 기타 오류: $e');
    }
    return null;
  }

  // 🎨 색칠 완성작 저장
  static Future<Map<String, dynamic>?> saveColoredImage({
    required Map<String, dynamic> coloringData,
  }) async {
    try {
      print('🔍 색칠 완성작 저장 요청');
      print('🔍 요청 URL: $baseUrl/api/coloring/save');
      print('🔍 요청 데이터: $coloringData');

      final response = await _dio.post(
        '/api/coloring/save',
        data: coloringData,
      );

      print('✅ 저장 응답 상태코드: ${response.statusCode}');
      print('✅ 저장 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ 색칠 완성작 저장 성공');
        return {'success': true, 'data': response.data};
      }
    } on DioException catch (e) {
      print('❌ 저장 네트워크 오류:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');
      }

      return {'success': false, 'error': e.message};
    } catch (e) {
      print('❌ 색칠 완성작 저장 실패: $e');
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }

  // 🔍 서버 연결 테스트 (새로 추가)
  static Future<bool> testConnection() async {
    try {
      print('🔍 서버 연결 테스트 시작: $baseUrl');

      final response = await _dio
          .get('/actuator/health')
          .timeout(Duration(seconds: 5));

      print('✅ 서버 연결 성공: ${response.statusCode}');
      return true;
    } catch (e) {
      print('❌ 서버 연결 실패: $e');
      return false;
    }
  }
}
