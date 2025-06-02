// 온보딩 화면
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: Center(
                child: Image.asset('assets/bear.png', fit: BoxFit.contain),
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView( // ⭐ 스크롤 추가
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        '"엄빠, 읽어도!"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26, // ⭐ 30에서 26으로 조정
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B2D2C),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '아이와 함께 쓰는 세상에 단 하나뿐인 이야기,\n지금 시작해요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18, // ⭐ 20에서 18로 조정
                          color: Color(0xFF754D19),
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF6B756),
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: TextStyle(
                            fontSize: 18, // ⭐ 20에서 18로 조정
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          'START',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}