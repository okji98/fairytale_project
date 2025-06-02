// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ⭐ 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // ⭐ 액세스 토큰 가져오기
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // ⭐ 리프레시 토큰 가져오기
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // ⭐ 로그아웃 (토큰 삭제)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.setBool('is_logged_in', false);
  }
}