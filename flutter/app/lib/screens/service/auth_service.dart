// lib/service/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _baseUrl = 'http://10.0.2.2:8080';

  // 토큰 저장
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userEmailKey, userEmail);
  }

  // Access Token 가져오기
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Refresh Token 가져오기
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // 사용자 ID 가져오기
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // 사용자 이메일 가져오기
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // ⭐ 아이 정보 확인 (토큰 갱신 로직 추가)
  static Future<Map<String, dynamic>?> checkChildInfo() async {
    try {
      final accessToken = await getAccessToken();
      final userId = await getUserId();

      if (accessToken == null || userId == null) {
        print('토큰 또는 사용자 ID 없음');
        return {'hasChild': false, 'childData': null};
      }

      final dio = Dio();
      print('아이 정보 확인 요청: userId=$userId');

      try {
        final response = await dio.get(
          '$_baseUrl/api/baby',
          queryParameters: {'userId': userId},
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );

        print('아이 정보 확인 응답: ${response.data}');

        if (response.statusCode == 200 && response.data['success'] == true) {
          return {
            'hasChild': response.data['hasChild'] ?? false,
            'childData': response.data['data'],
          };
        }

        // API는 성공했지만 아이 정보가 없는 경우
        return {'hasChild': false, 'childData': null};

      } catch (e) {
        // 403 에러 (토큰 만료) 처리
        if (e is DioException && e.response?.statusCode == 403) {
          print('토큰 만료, 갱신 시도...');

          // 토큰 갱신 시도
          final refreshSuccess = await refreshAccessToken();

          if (refreshSuccess) {
            print('토큰 갱신 성공, 재시도...');
            // 갱신된 토큰으로 재시도
            final newAccessToken = await getAccessToken();
            final retryResponse = await dio.get(
              '$_baseUrl/api/baby',
              queryParameters: {'userId': userId},
              options: Options(
                headers: {'Authorization': 'Bearer $newAccessToken'},
              ),
            );

            print('재시도 응답: ${retryResponse.data}');

            if (retryResponse.statusCode == 200 && retryResponse.data['success'] == true) {
              return {
                'hasChild': retryResponse.data['hasChild'] ?? false,
                'childData': retryResponse.data['data'],
              };
            }

            return {'hasChild': false, 'childData': null};
          } else {
            print('토큰 갱신 실패, 로그아웃 처리');
            await logout(); // 토큰 갱신 실패 시 로그아웃
            return null; // 로그인이 필요함을 의미
          }
        }

        // 다른 에러는 기본값 반환
        print('기타 에러: $e');
        return {'hasChild': false, 'childData': null};
      }

    } catch (e) {
      print('아이 정보 확인 오류: $e');
      // 오류 시에도 hasChild: false로 반환 (아이 정보 입력 화면으로 보내기)
      return {'hasChild': false, 'childData': null};
    }
  }

  // ⭐ 로그인 후 적절한 화면으로 이동하는 라우팅 로직 (에러 처리 강화)
  static Future<String> getNextRoute() async {
    try {
      // 1. 로그인 상태 확인
      final isAuthenticated = await isLoggedIn();
      if (!isAuthenticated) {
        print('로그인되지 않음 → /login');
        return '/login';
      }

      // 2. 아이 정보 확인
      final childInfo = await checkChildInfo();

      // 토큰 문제로 null이 반환된 경우 (로그인 필요)
      if (childInfo == null) {
        print('토큰 문제 발생 → /login');
        return '/login';
      }

      // 3. 아이 정보가 없으면 child_info_screen으로
      if (!childInfo['hasChild']) {
        print('아이 정보 없음 → /child-info');
        return '/child-info';
      }

      // 4. 모든 정보가 있으면 홈 화면으로
      print('모든 정보 완료 → /home');
      return '/home';

    } catch (e) {
      print('라우팅 결정 오류: $e');
      return '/onboarding'; // ⭐ 에러 시 온보딩으로 (안전한 fallback)
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    print('로그아웃 완료');
  }

  // ⭐ 토큰 갱신 (에러 처리 개선)
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        print('Refresh Token이 없음');
        return false;
      }

      final dio = Dio();
      print('토큰 갱신 요청...');

      final response = await dio.post(
        '$_baseUrl/oauth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, newAccessToken);
        print('토큰 갱신 성공');
        return true;
      }

      print('토큰 갱신 실패: ${response.statusCode}');
      return false;

    } catch (e) {
      print('토큰 갱신 오류: $e');
      return false;
    }
  }
}