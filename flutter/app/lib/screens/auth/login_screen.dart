import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../../main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // ✅ 카카오 로그인 (플랫폼별 처리)
  Future<String?> _loginWithKakao() async {
    try {
      print('🔍 카카오 로그인 시작');

      if (Platform.isMacOS) {
        // macOS에서는 웹 기반 로그인
        return await _loginWithKakaoWeb();
      } else {
        // iOS/Android에서는 네이티브 SDK
        bool isInstalled = await isKakaoTalkInstalled();
        OAuthToken token;
        if (isInstalled) {
          print('🔍 카카오톡 앱으로 로그인');
          token = await UserApi.instance.loginWithKakaoTalk();
        } else {
          print('🔍 카카오 계정으로 로그인');
          token = await UserApi.instance.loginWithKakaoAccount();
        }
        print('✅ 카카오 토큰 획득: ${token.accessToken.substring(0, 20)}...');
        return token.accessToken;
      }
    } catch (e) {
      print('❌ 카카오 로그인 오류: $e');
      return null;
    }
  }

  // 🆕 macOS용 웹 기반 카카오 로그인
  Future<String?> _loginWithKakaoWeb() async {
    try {
      print('🔍 macOS 웹 기반 카카오 로그인 시작');

      // 로컬 서버 시작
      final server = await HttpServer.bind('localhost', 8080);
      print('✅ 로컬 서버 시작: http://localhost:8080');

      // 카카오 로그인 URL 생성 및 브라우저 열기
      const clientId =
          'c65655b8bd8ad412ee16edb91d0ad084'; // 실제 REST API 키로 변경하세요
      const redirectUri = 'http://localhost:8080/auth/kakao/callback';

      final loginUrl =
          'https://kauth.kakao.com/oauth/authorize?'
          'client_id=$clientId&'
          'redirect_uri=${Uri.encodeComponent(redirectUri)}&'
          'response_type=code';

      // 시스템 브라우저로 로그인 URL 열기
      if (Platform.isMacOS) {
        await Process.run('open', [loginUrl]);
      }

      String? accessToken;

      // 서버에서 콜백 대기 (최대 5분)
      await for (HttpRequest request in server.timeout(Duration(minutes: 5))) {
        final response = request.response;

        if (request.uri.path == '/auth/kakao/callback') {
          final authCode = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];

          if (error != null) {
            print('❌ 카카오 로그인 오류: $error');
            response.headers.contentType = ContentType.html;
            response.write('''
              <html><body>
                <h2>로그인 실패</h2>
                <p>오류: $error</p>
                <p>이 창을 닫고 앱으로 돌아가세요.</p>
              </body></html>
            ''');
            break;
          } else if (authCode != null) {
            // Access Token 획득
            accessToken = await _getKakaoAccessToken(
              authCode,
              clientId,
              redirectUri,
            );

            response.headers.contentType = ContentType.html;
            if (accessToken != null) {
              response.write('''
                <html><body>
                  <h2>로그인 성공!</h2>
                  <p>이 창을 닫고 앱으로 돌아가세요.</p>
                  <script>setTimeout(() => window.close(), 2000);</script>
                </body></html>
              ''');
              print('✅ 카카오 웹 로그인 성공');
            } else {
              response.write('''
                <html><body>
                  <h2>토큰 획득 실패</h2>
                  <p>다시 시도해주세요.</p>
                </body></html>
              ''');
            }
            break;
          }
        }

        await response.close();
      }

      await server.close();
      return accessToken;
    } catch (e) {
      print('❌ 카카오 웹 로그인 오류: $e');
      return null;
    }
  }

  //TEST CODE
  // 기존 _getKakaoAccessToken 메서드를 이것으로 교체하세요

  // 🆕 카카오 Access Token 획득
  Future<String?> _getKakaoAccessToken(
    String authCode,
    String clientId,
    String redirectUri,
  ) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://kauth.kakao.com/oauth/token',
        data: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'code': authCode,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        return tokenData['access_token'];
      }
      return null;
    } catch (e) {
      print('❌ 카카오 토큰 획득 오류: $e');
      return null;
    }
  }

  // ✅ 구글 로그인 (기존과 동일)
  Future<String?> _loginWithGoogle() async {
    try {
      print('🔍 구글 로그인 시작');
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        print("❌ 구글 로그인 취소됨");
        return null;
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final idToken = auth.idToken;
      print("✅ 구글 토큰 획득: ${idToken?.substring(0, 20)}...");
      return idToken;
    } catch (e) {
      print('❌ 구글 로그인 오류: $e');
      return null;
    }
  }

  // ✅ 토큰 서버에 전송 및 저장 (기존과 동일)
  Future<Map<String, dynamic>?> _sendTokenToServer(
    String accessToken,
    String provider,
  ) async {
    try {
      print('🔍 서버로 토큰 전송 시작 - Provider: $provider');
      final dio = Dio();

      final response = await dio.post(
        'http://localhost:8080/oauth/login',
        data: {'provider': provider, 'accessToken': accessToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      print('✅ 서버 응답 성공 - 상태코드: ${response.statusCode}');
      print('✅ 서버 응답 데이터: ${response.data}');

      if (response.data != null && response.data['accessToken'] != null) {
        print('🔍 JWT 토큰 저장 시작');
        final prefs = await SharedPreferences.getInstance();

        final accessTokenSaved = await prefs.setString(
          'access_token',
          response.data['accessToken'],
        );
        final refreshTokenSaved = await prefs.setString(
          'refresh_token',
          response.data['refreshToken'] ?? '',
        );
        final loginStatusSaved = await prefs.setBool('is_logged_in', true);

        print('✅ Access Token 저장 성공: $accessTokenSaved');
        print('✅ Refresh Token 저장 성공: $refreshTokenSaved');
        print('✅ 로그인 상태 저장 성공: $loginStatusSaved');

        return {
          'success': true,
          'accessToken': response.data['accessToken'],
          'refreshToken': response.data['refreshToken'],
        };
      } else {
        print('❌ 서버 응답에 accessToken이 없음');
        return null;
      }
    } on DioException catch (e) {
      print('❌ 네트워크 오류: ${e.type}');
      print('❌ 오류 메시지: ${e.message}');
      if (e.response != null) {
        print('❌ 서버 응답 코드: ${e.response?.statusCode}');
        print('❌ 서버 응답 데이터: ${e.response?.data}');
      }

      // 서버 연결 실패시 임시 로그인 상태 저장 (개발용)
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        print('🎭 서버 연결 실패 - 오프라인 모드로 로그인 상태 저장');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString(
          'access_token',
          'offline-${provider}-${DateTime.now().millisecondsSinceEpoch}',
        );

        return {
          'success': true,
          'accessToken': 'offline-${provider}-token',
          'refreshToken': 'offline-refresh-token',
        };
      }

      return null;
    } catch (e) {
      print('❌ 서버 전송 오류: $e');
      return null;
    }
  }

  // 에러 다이얼로그 (기존과 동일)
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('로그인 오류'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  // ⭐ 로그인 성공 후 홈화면으로 이동 (기존과 동일)
  void _navigateToHome(BuildContext context) {
    print('🔍 홈화면으로 이동 시도');
    Navigator.pushReplacementNamed(context, '/home')
        .then((_) {
          print('✅ 홈화면 이동 완료');
        })
        .catchError((error) {
          print('❌ 홈화면 이동 실패: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.brown),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const Spacer(),
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
                    width: MediaQuery.of(context).size.width * 0.6,
                    fit: BoxFit.contain,
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
                    onTap: () async {
                      print('🔍 카카오 로그인 버튼 클릭');
                      final kakaoToken = await _loginWithKakao();
                      if (kakaoToken != null) {
                        final loginData = await _sendTokenToServer(
                          kakaoToken,
                          'kakao',
                        );
                        if (loginData != null && loginData['success'] == true) {
                          print('✅ 로그인 성공! 홈화면으로 이동');
                          _navigateToHome(context);
                        } else {
                          print('❌ 로그인 실패');
                          _showErrorDialog(context, '카카오 로그인에 실패했습니다.');
                        }
                      } else {
                        print('❌ 카카오 토큰 획득 실패');
                      }
                    },
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
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
                    onTap: () async {
                      print('🔍 구글 로그인 버튼 클릭');
                      final googleToken = await _loginWithGoogle();
                      if (googleToken != null) {
                        final loginData = await _sendTokenToServer(
                          googleToken,
                          'google',
                        );
                        if (loginData != null && loginData['success'] == true) {
                          print('✅ 로그인 성공! 홈화면으로 이동');
                          _navigateToHome(context);
                        } else {
                          print('❌ 로그인 실패');
                          _showErrorDialog(context, '구글 로그인에 실패했습니다.');
                        }
                      } else {
                        print('❌ 구글 토큰 획득 실패');
                      }
                    },
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.83,
                      height: 48,
                      child: Image.asset(
                        'assets/google_login.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🆕 플랫폼 정보 표시
                  Text(
                    Platform.isMacOS
                        ? '💻 macOS - 웹 기반 로그인 사용'
                        : '📱 모바일 - 네이티브 로그인 사용',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // 개발용 테스트 버튼
                  ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_logged_in', true);
                      await prefs.setString(
                        'access_token',
                        'fake-token-for-testing',
                      );
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      minimumSize: Size(
                        MediaQuery.of(context).size.width * 0.8,
                        48,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '홈화면 test 이동 (개발용)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
