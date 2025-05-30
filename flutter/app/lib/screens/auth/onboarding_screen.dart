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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '“엄빠, 읽어도!”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B2D2C),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '아이와 함께 쓰는 세상에 단 하나뿐인 이야기,\n지금 시작해요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9E9E9E),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text('START'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}