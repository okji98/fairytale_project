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

  // 🎯 색칠 완성작 저장 (Base64 이미지 포함) - 새로 추가
  static Future<Map<String, dynamic>?> saveColoredImageWithCapture({
    required Map<String, dynamic> coloringData,
  }) async {
    try {
      print('🎨 [ApiService] 색칠 완성작 저장 시작 (캡처 방식)');
      print('🎨 [ApiService] 원본 이미지: ${coloringData['originalImageUrl']}');
      print(
        '🎨 [ApiService] Base64 길이: ${coloringData['completedImageBase64']?.length ?? 0}',
      );

      final response = await _dio.post(
        '/api/coloring/save',
        data: coloringData,
      );

      print('🎨 [ApiService] 색칠 완성작 저장 응답 상태: ${response.statusCode}');
      print('🎨 [ApiService] 응답 본문: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 🎯 응답을 Map으로 안전하게 변환
        Map<String, dynamic> resultMap;
        if (responseData is Map<String, dynamic>) {
          resultMap = responseData;
        } else if (responseData is Map) {
          // Map이지만 타입이 다른 경우 변환
          resultMap = Map<String, dynamic>.from(responseData);
        } else {
          // Map이 아닌 경우 기본 성공 응답 생성
          print('⚠️ [ApiService] 응답이 Map이 아님: ${responseData.runtimeType}');
          print('⚠️ [ApiService] 응답 내용: $responseData');
          resultMap = {
            'success': true,
            'message': '색칠 완성작이 저장되었습니다.',
            'data': responseData,
          };
        }

        // 🎯 success 필드 확인 및 처리
        if (resultMap['success'] == true || !resultMap.containsKey('success')) {
          // success가 true이거나 success 필드가 없는 경우 성공으로 처리
          if (!resultMap.containsKey('success')) {
            resultMap['success'] = true;
          }
          print('✅ [ApiService] 색칠 완성작 저장 성공');
          return resultMap;
        } else {
          print(
            '❌ [ApiService] 서버에서 실패 응답: ${resultMap['error'] ?? '알 수 없는 오류'}',
          );
          return resultMap;
        }
      } else {
        print('❌ [ApiService] 색칠 완성작 저장 실패: ${response.statusCode}');
        return {'success': false, 'error': '서버 오류: ${response.statusCode}'};
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 색칠 완성작 저장 네트워크 오류:');
      print('  - 오류 타입: ${e.type}');
      print('  - 오류 메시지: ${e.message}');

      if (e.response != null) {
        print('  - 서버 응답 코드: ${e.response?.statusCode}');
        print('  - 서버 응답 데이터: ${e.response?.data}');
      }

      return {'success': false, 'error': e.message ?? '네트워크 오류'};
    } catch (e) {
      print('❌ [ApiService] 색칠 완성작 저장 오류: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 🎨 색칠공부 템플릿 검색 - 새로 추가
  static Future<List<Map<String, dynamic>>?> searchColoringTemplates({
    required String keyword,
    int page = 0,
    int size = 20,
  }) async {
    try {
      print('🎨 [ApiService] 색칠공부 템플릿 검색 시작 - 키워드: $keyword');

      final response = await _dio.get(
        '/api/coloring/templates/search',
        queryParameters: {'keyword': keyword, 'page': page, 'size': size},
      );

      print('🎨 [ApiService] 색칠공부 템플릿 검색 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['success'] == true) {
          final List<dynamic> templatesJson = responseData['templates'] ?? [];

          final templates =
              templatesJson
                  .map((json) => Map<String, dynamic>.from(json))
                  .toList();

          print('✅ [ApiService] 색칠공부 템플릿 검색 결과 ${templates.length}개');
          return templates;
        } else {
          print('❌ [ApiService] 예상과 다른 검색 응답 구조: $responseData');
        }
      } else {
        print('❌ [ApiService] 색칠공부 템플릿 검색 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 검색 오류: ${e.message}');
    } catch (e) {
      print('❌ [ApiService] 색칠공부 템플릿 검색 오류: $e');
    }
    return null;
  }

  // 🎯 특정 템플릿 상세 조회 - 새로 추가
  static Future<Map<String, dynamic>?> getColoringTemplateDetail(
    int templateId,
  ) async {
    try {
      print('🎨 [ApiService] 색칠공부 템플릿 상세 조회 - ID: $templateId');

      final response = await _dio.get('/api/coloring/templates/$templateId');

      print('🎨 [ApiService] 템플릿 상세 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['success'] == true) {
          print('✅ [ApiService] 템플릿 상세 조회 성공');
          return responseData['template'];
        }
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 템플릿 상세 조회 오류: ${e.message}');
    } catch (e) {
      print('❌ [ApiService] 템플릿 상세 조회 오류: $e');
    }
    return null;
  }

  // 🎯 동화 ID로 색칠공부 템플릿 조회 - 새로 추가
  static Future<Map<String, dynamic>?> getColoringTemplateByStoryId(
    String storyId,
  ) async {
    try {
      print('🎨 [ApiService] 동화별 색칠공부 템플릿 조회 - StoryId: $storyId');

      final response = await _dio.get('/api/coloring/templates/story/$storyId');

      print('🎨 [ApiService] 동화별 템플릿 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['success'] == true) {
          print('✅ [ApiService] 동화별 템플릿 조회 성공');
          return responseData['template'];
        }
      } else if (response.statusCode == 404) {
        print('⚠️ [ApiService] 해당 동화의 색칠공부 템플릿이 없음');
        return null;
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 동화별 템플릿 조회 오류: ${e.message}');
    } catch (e) {
      print('❌ [ApiService] 동화별 템플릿 조회 오류: $e');
    }
    return null;
  }

  // 🎯 서버 연결 상태 확인 - 새로 추가
  static Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      print('🔍 [ApiService] 서버 상태 확인 시작: $baseUrl');

      final response = await _dio
          .get('/actuator/health')
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ [ApiService] 서버 연결 성공');
        return {
          'connected': true,
          'status': 'UP',
          'message': '서버가 정상적으로 작동 중입니다.',
        };
      } else {
        return {
          'connected': false,
          'status': 'ERROR',
          'message': '서버 응답 오류: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('❌ [ApiService] 서버 연결 실패: ${e.message}');

      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '서버 연결 시간 초과';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '서버에 연결할 수 없습니다';
      } else {
        errorMessage = '네트워크 오류: ${e.message}';
      }

      return {'connected': false, 'status': 'DOWN', 'message': errorMessage};
    } catch (e) {
      print('❌ [ApiService] 서버 상태 확인 오류: $e');
      return {
        'connected': false,
        'status': 'UNKNOWN',
        'message': '알 수 없는 오류: $e',
      };
    }
  }
}
