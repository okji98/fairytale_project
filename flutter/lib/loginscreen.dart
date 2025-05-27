import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // 구글 로그인
  void _loginWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final account = await googleSignIn.signIn();
    final auth = await account?.authentication;
    final idToken = auth?.idToken;
    print('Google ID Token: $idToken');
  }

  // 카카오 로그인
  void _loginWithKakao() async {
    try {
      bool installed = await isKakaoTalkInstalled();
      OAuthToken token = installed
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      print('Kakao Access Token: ${token.accessToken}');
    } catch (e) {
      print('카카오 로그인 실패: $e');
    }
  }

  // // 애플 로그인
  // void _loginWithApple() async {
  //   final credential = await SignInWithApple.getAppleIDCredential(
  //     scopes: [AppleIDAuthorizationScopes.email],
  //   );
  //   print('Apple ID Token: ${credential.identityToken}');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        backgroundColor: const Color(0xFFFAE2EA),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SNS 계정으로 로그인',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // 구글 로그인 버튼
            ElevatedButton(
              onPressed: _loginWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login),
                  SizedBox(width: 8),
                  Text('구글 로그인'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 카카오 로그인 버튼
            ElevatedButton(
              onPressed: _loginWithKakao,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE500),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('카카오 로그인'),
            ),

            const SizedBox(height: 16),


            // // 애플 로그인 버튼
            // SignInWithAppleButton(
            //   onPressed: _loginWithApple,
            //   style: SignInWithAppleButtonStyle.black,
            // ),

            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                // 회원가입 화면으로 이동 (SNS만 쓰면 생략 가능)
              },
              child: const Text('이메일 대신 SNS로 로그인하세요'),
            ),
          ],
        ),
      ),
    );
  }
}
