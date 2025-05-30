// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = false;
  bool _darkModeEnabled = false;
  String _selectedLanguage = '한국어';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 앱바
                Container(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                          'Settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.06),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // 알림 설정
                _buildSectionTitle(context, '알림 설정'),
                SizedBox(height: screenHeight * 0.015),

                _buildSwitchTile(
                  context,
                  title: '푸시 알림',
                  subtitle: '새로운 동화와 업데이트 알림',
                  icon: Icons.notifications,
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.01),

                _buildSwitchTile(
                  context,
                  title: '소리',
                  subtitle: '알림음 및 효과음',
                  icon: Icons.volume_up,
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.01),

                _buildSwitchTile(
                  context,
                  title: '진동',
                  subtitle: '알림 시 진동',
                  icon: Icons.vibration,
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.03),

                // 화면 설정
                _buildSectionTitle(context, '화면 설정'),
                SizedBox(height: screenHeight * 0.015),

                _buildSwitchTile(
                  context,
                  title: '다크 모드',
                  subtitle: '어두운 테마 사용',
                  icon: Icons.dark_mode,
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // TODO: 다크 모드 적용 로직 구현
                  },
                ),

                SizedBox(height: screenHeight * 0.01),

                _buildOptionTile(
                  context,
                  title: '언어',
                  subtitle: _selectedLanguage,
                  icon: Icons.language,
                  onTap: () => _showLanguageDialog(),
                ),

                SizedBox(height: screenHeight * 0.03),

                // 개인정보 설정
                _buildSectionTitle(context, '개인정보'),
                SizedBox(height: screenHeight * 0.015),

                _buildOptionTile(
                  context,
                  title: '개인정보 처리방침',
                  subtitle: '개인정보 보호 정책 확인',
                  icon: Icons.privacy_tip,
                  onTap: () {
                    // TODO: 개인정보 처리방침 화면으로 이동
                    Navigator.pushNamed(context, '/privacy-policy');
                  },
                ),

                SizedBox(height: screenHeight * 0.01),

                _buildOptionTile(
                  context,
                  title: '이용약관',
                  subtitle: '서비스 이용약관 확인',
                  icon: Icons.description,
                  onTap: () {
                    // TODO: 이용약관 화면으로 이동
                    Navigator.pushNamed(context, '/terms-of-service');
                  },
                ),

                SizedBox(height: screenHeight * 0.03),

                // 기타
                _buildSectionTitle(context, '기타'),
                SizedBox(height: screenHeight * 0.015),

                _buildOptionTile(
                  context,
                  title: '앱 버전',
                  subtitle: 'v1.0.0',
                  icon: Icons.info,
                  onTap: () {
                    _showVersionDialog();
                  },
                ),

                SizedBox(height: screenHeight * 0.01),

                _buildOptionTile(
                  context,
                  title: '캐시 삭제',
                  subtitle: '임시 파일 및 캐시 삭제',
                  icon: Icons.cleaning_services,
                  onTap: () {
                    _showClearCacheDialog();
                  },
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Text(
      title,
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B5A6B),
      ),
    );
  }

  Widget _buildSwitchTile(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required bool value,
        required ValueChanged<bool> onChanged,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFF5E6A3).withOpacity(0.3),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF8E97FD),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.015,
        ),
        decoration: BoxDecoration(
          color: Color(0xFFF5E6A3).withOpacity(0.3),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('언어 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('한국어'),
              _buildLanguageOption('English'),
              _buildLanguageOption('日本語'),
              _buildLanguageOption('中文'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      groupValue: _selectedLanguage,
      onChanged: (String? value) {
        setState(() {
          _selectedLanguage = value!;
        });
        Navigator.pop(context);
        // TODO: 언어 변경 로직 구현
      },
      activeColor: Color(0xFF8E97FD),
    );
  }

  void _showVersionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('앱 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('버전: v1.0.0'),
              SizedBox(height: 8),
              Text('빌드: 2024.05.30'),
              SizedBox(height: 8),
              Text('개발: 1조 팀'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('캐시 삭제'),
          content: Text('캐시를 삭제하시겠습니까?\n임시 파일과 저장된 데이터가 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 실제 캐시 삭제 로직 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('캐시가 삭제되었습니다.'),
                    backgroundColor: Color(0xFF8E97FD),
                  ),
                );
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}