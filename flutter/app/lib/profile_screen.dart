// lib/profile_screen.dart
import 'package:flutter/material.dart';
import 'main.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: SingleChildScrollView( // 스크롤 가능하도록 추가
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // 상단 앱바
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.02
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black54,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.06), // 균형을 위한 공간
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // 프로필 이미지와 정보
                Column(
                  children: [
                    // 프로필 이미지
                    Stack(
                      children: [
                        Container(
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF9C7CB8),
                                Color(0xFFB8A5D1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: screenWidth * 0.2,
                              height: screenWidth * 0.2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFDB5A6),
                              ),
                              child: Center(
                                child: Text(
                                  '👶',
                                  style: TextStyle(fontSize: screenWidth * 0.1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: 프로필 사진 업로드 기능 구현
                              _showImagePickerDialog(context);
                            },
                            child: Container(
                              width: screenWidth * 0.09,
                              height: screenWidth * 0.09,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF8B5A6B),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: screenWidth * 0.045,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // 이름
                    Text(
                      '동글이',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    // 이메일
                    Text(
                      'donggeul@example.com',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.04),

                // 메뉴 리스트
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.person,
                        title: 'Profile details',
                        onTap: () {
                          // TODO: Profile details 화면으로 이동
                          Navigator.pushNamed(context, '/profile-details');
                        },
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      _buildMenuItem(
                        context,
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () {
                          // TODO: Settings 화면으로 이동
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      _buildMenuItem(
                        context,
                        icon: Icons.notifications,
                        title: 'Contacts',
                        onTap: () {
                          // TODO: Contacts 화면으로 이동
                          Navigator.pushNamed(context, '/contacts');
                        },
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      _buildMenuItem(
                        context,
                        icon: Icons.help_outline,
                        title: 'Support',
                        onTap: () {
                          // TODO: Support 화면으로 이동
                          Navigator.pushNamed(context, '/support');
                        },
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      _buildMenuItem(
                        context,
                        icon: Icons.logout,
                        title: 'Logout',
                        onTap: () {
                          _showLogoutDialog(context);
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02
        ),
        decoration: BoxDecoration(
          color: Color(0xFFF5E6A3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.7),
              ),
              child: Icon(
                icon,
                color: Color(0xFF8B5A6B),
                size: screenWidth * 0.05,
              ),
            ),

            SizedBox(width: screenWidth * 0.04),

            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            Spacer(),

            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black38,
              size: screenWidth * 0.04,
            ),
          ],
        ),
      ),
    );
  }

  // TODO: 프로필 사진 업로드 다이얼로그 구현
  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('프로필 사진 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 카메라 촬영 기능 구현
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 갤러리 선택 기능 구현
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

  // TODO: 카메라 촬영 기능 구현
  void _pickImageFromCamera() {
    // image_picker 패키지 사용하여 카메라 촬영 구현 예정
    print('카메라로 사진 촬영');
  }

  // TODO: 갤러리 선택 기능 구현
  void _pickImageFromGallery() {
    // image_picker 패키지 사용하여 갤러리 선택 구현 예정
    print('갤러리에서 사진 선택');
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그아웃'),
          content: Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                ); // 로그인 화면으로 이동하고 스택 클리어
              },
              child: Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }
}