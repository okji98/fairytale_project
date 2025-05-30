import 'dart:convert';                         // jsonEncode, jsonDecode 사용
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;      // add http: ^0.13.0 in pubspec.yaml
import 'package:app/social_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // ────────────────────────────────────────────
  // 스프링부트 API 로그인 호출 함수들
  // ────────────────────────────────────────────

  // 1) 카카오 로그인 후 토큰을 받아와 스프링부트에 전달
  Future<void> _loginWithKakao(BuildContext context) async {
    try {
      // TODO: 실제로는 카카오 SDK 호출해서 토큰 얻기
      final kakaoToken = await _simulateKakaoLogin();

      // ─ API 호출 위치
      final response = await http.post(
        Uri.parse('http://your-spring-domain.com/api/auth/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': kakaoToken}),
      );
      // ────────────────────────────────────────

      if (response.statusCode == 200) {
        // 로그인 성공 시 처리 (예: 토큰 저장, 홈 화면 이동)
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // 로그인 실패 처리
        _showErrorDialog(context, '카카오 로그인에 실패했습니다.');
      }
    } catch (e) {
      _showErrorDialog(context, '네트워크 오류가 발생했습니다.');
    }
  }

  // 2) 구글 로그인 후 토큰을 받아와 스프링부트에 전달
  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      // TODO: 실제로는 구글 SDK 호출해서 토큰 얻기
      final googleToken = await _simulateGoogleLogin();

      // ─ API 호출 위치
      final response = await http.post(
        Uri.parse('http://your-spring-domain.com/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': googleToken}),
      );
      // ────────────────────────────────────────

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorDialog(context, '구글 로그인에 실패했습니다.');
      }
    } catch (e) {
      _showErrorDialog(context, '네트워크 오류가 발생했습니다.');
    }
  }

  // ────────────────────────────────────────────
  // 예시용 시뮬레이션 & 에러 다이얼로그
  // ────────────────────────────────────────────

  Future<String> _simulateKakaoLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    return 'dummy_kakao_token';
  }

  Future<String> _simulateGoogleLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    return 'dummy_google_token';
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그인 오류'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/bg_image.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 상단 바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // 로고 영역 (필요 시 활성화)
                      // Image.asset('assets/book_bear.png', height: 24),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),

                // 중앙 로그인 버튼들
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/book_bear.png',
                        width: MediaQuery.of(context).size.width * 0.6, // 화면 너비의 60%
                        fit: BoxFit.contain,                            // 비율 유지
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 카카오 로그인 버튼
                      GestureDetector(
                        onTap: () => _loginWithKakao(context),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,  // 80%로 통일
                          height: 48,
                          child: Image.asset(
                            'assets/kakao_login.png',
                            fit: BoxFit.cover,
                          ),
                        ),

                      ),
                      const SizedBox(height: 12),

                      // 구글 로그인 버튼
                      GestureDetector(
                        onTap: () => _loginWithGoogle(context),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,  // 80%로 통일
                          height: 48,
                          child: Image.asset(
                            'assets/google_login.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
