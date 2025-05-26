import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'aistorypage.dart';
import 'loginscreen.dart';
import 'mypagescreen.dart';
import 'upload_board_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _mainMoved = false;
  final List<Widget> _pages = [
    const Center(child: Text('홈 화면')),
    const AIStoryPage(),
    const UploadBoardScreen(),
    const MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        leadingWidth: 100,
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _currentIndex = 0),
            splashColor: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(70),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                'assets/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                // 로그인 버튼 터치 시 LoginScreen으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                'LOGIN',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: _currentIndex == 0
          ? AnimatedAlign(
        alignment:
        _mainMoved ? Alignment.topCenter : Alignment.center,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTap: () => setState(() => _mainMoved = !_mainMoved),
          child: Image.asset(
            'assets/main.png',
            width: 400,
            height: 400,
          ),
        ),
      )
          : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: '홈화면'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories), label: '동화세상'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book), label: '커뮤니티'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: '마이페이지'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
    );
  }
}