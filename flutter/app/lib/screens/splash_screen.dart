// lib/screens/splash_screen.dart
import 'package:app/screens/service/auth_service.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // 2초 대기 (스플래시 화면 표시)
    await Future.delayed(Duration(seconds: 2));

    // 다음 화면 결정
    final nextRoute = await AuthService.getNextRoute();

    // 해당 화면으로 이동
    if (mounted) {
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5E6A3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고나 앱 이름
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFF8B5A6B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories,
                size: 60,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 24),

            Text(
              'FairyTale',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5A6B),
              ),
            ),

            SizedBox(height: 12),

            Text(
              '우리 아이를 위한 동화',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8B5A6B).withOpacity(0.7),
              ),
            ),

            SizedBox(height: 48),

            // 로딩 인디케이터
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5A6B)),
            ),
          ],
        ),
      ),
    );
  }
}