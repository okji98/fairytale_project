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

  // 🆕 아이 정보 확인
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
      print('아이 정보 확인 오류: $e');
      // 오류 시에도 hasChild: false로 반환 (아이 정보 입력 화면으로 보내기)
      return {'hasChild': false, 'childData': null};
    }
  }

  // 🆕 로그인 후 적절한 화면으로 이동하는 라우팅 로직
  static Future<String> getNextRoute() async {
    try {
      // 1. 로그인 상태 확인
      final isAuthenticated = await isLoggedIn();
      if (!isAuthenticated) {
        return '/login';
      }

      // 2. 아이 정보 확인
      final childInfo = await checkChildInfo();
      if (childInfo == null) {
        // API 오류 시 로그인 화면으로
        return '/login';
      }

      // 3. 아이 정보가 없으면 child_info_screen으로
      if (!childInfo['hasChild']) {
        return '/child-info';
      }

      // 4. 모든 정보가 있으면 홈 화면으로
      return '/home';
    } catch (e) {
      print('라우팅 결정 오류: $e');
      return '/login';
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  // 토큰 갱신
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final dio = Dio();
      final response = await dio.post(
        '$_baseUrl/oauth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, newAccessToken);
        return true;
      }

      return false;
    } catch (e) {
      print('토큰 갱신 오류: $e');
      return false;
    }
  }
}