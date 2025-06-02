import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // ✅ 카카오 로그인
  Future<String?> _loginWithKakao() async {
    try {
      print('🔍 카카오 로그인 시작');
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
    } catch (e) {
      print('❌ 카카오 로그인 오류: $e');
      return null;
    }
  }

  // ✅ 구글 로그인
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

  // ✅ 토큰 서버에 전송 및 저장
  Future<Map<String, dynamic>?> _sendTokenToServer(String accessToken, String provider) async {
    try {
      print('🔍 서버로 토큰 전송 시작 - Provider: $provider');
      final dio = Dio();

      final response = await dio.post(
        'http://10.0.2.2:8080/oauth/login',
        data: {
          'provider': provider,
          'accessToken': accessToken
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      print('✅ 서버 응답 성공 - 상태코드: ${response.statusCode}');
      print('✅ 서버 응답 데이터: ${response.data}');

      if (response.data != null && response.data['accessToken'] != null) {
        // ⭐ JWT 토큰을 SharedPreferences에 저장
        print('🔍 JWT 토큰 저장 시작');
        final prefs = await SharedPreferences.getInstance();

        final accessTokenSaved = await prefs.setString('access_token', response.data['accessToken']);
        final refreshTokenSaved = await prefs.setString('refresh_token', response.data['refreshToken'] ?? '');
        final loginStatusSaved = await prefs.setBool('is_logged_in', true);

        print('✅ Access Token 저장 성공: $accessTokenSaved');
        print('✅ Refresh Token 저장 성공: $refreshTokenSaved');
        print('✅ 로그인 상태 저장 성공: $loginStatusSaved');

        // 저장된 값 확인
        final savedAccessToken = await prefs.getString('access_token');
        final savedLoginStatus = await prefs.getBool('is_logged_in');
        print('🔍 저장 확인 - Access Token: ${savedAccessToken?.substring(0, 20)}...');
        print('🔍 저장 확인 - 로그인 상태: $savedLoginStatus');

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
      return null;
    } catch (e) {
      print('❌ 서버 전송 오류: $e');
      return null;
    }
  }

  // 에러 다이얼로그
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그인 오류'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인')
          ),
        ],
      ),
    );
  }

  // ⭐ 로그인 성공 후 홈화면으로 이동
  void _navigateToHome(BuildContext context) {
    print('🔍 홈화면으로 이동 시도');
    Navigator.pushReplacementNamed(context, '/home').then((_) {
      print('✅ 홈화면 이동 완료');
    }).catchError((error) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                        final loginData = await _sendTokenToServer(kakaoToken, 'kakao');
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
                        final loginData = await _sendTokenToServer(googleToken, 'google');
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

                  // 테스트용 홈화면 이동 버튼
                  ElevatedButton(
                    onPressed: () => _navigateToHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 48),
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

                  const SizedBox(height: 12),

                  // ⭐ 디버깅용 버튼들 추가
                  Column(
                    children: [
                      // 서버 연결 테스트
                      ElevatedButton(
                        onPressed: () async {
                          print('🔍 서버 연결 테스트 시작');
                          try {
                            final dio = Dio();
                            final response = await dio.post(
                              'http://10.0.2.2:8080/oauth/login',
                              data: {
                                'provider': 'test',
                                'accessToken': 'test-token'
                              },
                              options: Options(
                                headers: {'Content-Type': 'application/json'},
                                sendTimeout: Duration(seconds: 5),
                                receiveTimeout: Duration(seconds: 5),
                              ),
                            );
                            print('✅ 서버 연결 성공 - 상태코드: ${response.statusCode}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('서버 연결 성공! 코드: ${response.statusCode}')),
                            );
                          } on DioException catch (e) {
                            print('🔍 DioException 상세 정보:');
                            print('❌ 타입: ${e.type}');
                            print('❌ 메시지: ${e.message}');
                            print('❌ 응답 코드: ${e.response?.statusCode}');
                            print('❌ 응답 데이터: ${e.response?.data}');

                            String message = '';
                            if (e.type == DioExceptionType.badResponse) {
                              // 서버는 연결되었지만 에러 응답
                              message = '서버 연결됨! 응답코드: ${e.response?.statusCode}';
                              print('✅ 서버 연결은 성공! (${e.response?.statusCode} 응답)');
                            } else if (e.type == DioExceptionType.connectionTimeout) {
                              message = '연결 타임아웃';
                            } else if (e.type == DioExceptionType.connectionError) {
                              message = '연결 실패 - 서버 확인 필요';
                            } else {
                              message = '기타 오류: ${e.type}';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          } catch (e) {
                            print('❌ 예상치 못한 오류: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('예상치 못한 오류: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 48),
                        ),
                        child: const Text('서버 연결 테스트'),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
                              final accessToken = prefs.getString('access_token');
                              print('🔍 현재 로그인 상태: $isLoggedIn');
                              print('🔍 저장된 토큰: ${accessToken?.substring(0, 20) ?? 'null'}...');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('로그인 상태: $isLoggedIn')),
                              );
                            },
                            child: const Text('상태 확인'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear();
                              print('🔍 모든 저장된 데이터 삭제');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('데이터 초기화 완료')),
                              );
                            },
                            child: const Text('데이터 초기화'),
                          ),
                        ],
                      ),
                    ],
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