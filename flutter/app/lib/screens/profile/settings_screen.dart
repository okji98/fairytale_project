// lib/screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('설정 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('설정 저장 오류: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('캐시 삭제 중...'),
            ],
          ),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final cacheKeys = keys.where((key) =>
      !key.startsWith('notifications_') &&
          !key.startsWith('sound_') &&
          key != 'access_token' &&
          key != 'refresh_token' &&
          key != 'user_id' &&
          key != 'user_email'
      ).toList();

      for (String key in cacheKeys) {
        await prefs.remove(key);
      }

      await Future.delayed(Duration(seconds: 2));

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('캐시가 성공적으로 삭제되었습니다.'),
          backgroundColor: Color(0xFF8B5A6B),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('캐시 삭제 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return BaseScaffold(
        child: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5A6B)),
            ),
          ),
        ),
      );
    }

    return BaseScaffold(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더 (child_info_screen 스타일)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5A6B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '설정',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A6B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 균형 맞추기
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // 스크롤 가능한 콘텐츠 영역
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 알림 설정 섹션
                      _buildSectionTitle('알림 설정', screenWidth),
                      SizedBox(height: screenHeight * 0.015),

                      // 푸시 알림 설정
                      _buildSettingItem(
                        context,
                        icon: Icons.notifications,
                        title: '푸시 알림',
                        subtitle: '새로운 동화와 업데이트 알림',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) async {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                            await _saveSetting('notifications_enabled', value);
                          },
                          activeColor: Color(0xFF8B5A6B),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // 소리 설정
                      _buildSettingItem(
                        context,
                        icon: Icons.volume_up,
                        title: '소리',
                        subtitle: '알림음 및 효과음',
                        trailing: Switch(
                          value: _soundEnabled,
                          onChanged: (value) async {
                            setState(() {
                              _soundEnabled = value;
                            });
                            await _saveSetting('sound_enabled', value);
                          },
                          activeColor: Color(0xFF8B5A6B),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // 개인정보 섹션
                      _buildSectionTitle('개인정보', screenWidth),
                      SizedBox(height: screenHeight * 0.015),

                      // 개인정보 처리방침
                      _buildSettingItem(
                        context,
                        icon: Icons.privacy_tip,
                        title: '개인정보 처리방침',
                        subtitle: '개인정보 보호 정책 확인',
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black38,
                          size: screenWidth * 0.04,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('준비중'),
                              content: Text('개인정보 처리방침 기능을 준비 중입니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('확인'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // 이용약관
                      _buildSettingItem(
                        context,
                        icon: Icons.description,
                        title: '이용약관',
                        subtitle: '서비스 이용약관 확인',
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black38,
                          size: screenWidth * 0.04,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('준비중'),
                              content: Text('이용약관 기능을 준비 중입니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('확인'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // 기타 섹션
                      _buildSectionTitle('기타', screenWidth),
                      SizedBox(height: screenHeight * 0.015),

                      // 앱 버전
                      _buildSettingItem(
                        context,
                        icon: Icons.info,
                        title: '앱 버전',
                        subtitle: 'v1.0.0',
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black38,
                          size: screenWidth * 0.04,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('앱 정보'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('앱 이름: 엄빠, 읽어도!'),
                                  SizedBox(height: 8),
                                  Text('버전: v1.0.0'),
                                  SizedBox(height: 8),
                                  Text('빌드: 2024.06.11'),
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
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // 캐시 삭제
                      _buildSettingItem(
                        context,
                        icon: Icons.cleaning_services,
                        title: '캐시 삭제',
                        subtitle: '임시 파일 및 저장된 데이터 삭제',
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black38,
                          size: screenWidth * 0.04,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('캐시 삭제'),
                              content: Text('앱의 임시 파일과 캐시 데이터를 삭제하시겠습니까?\n\n로그인 정보와 설정은 유지됩니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearCache();
                                  },
                                  child: Text('삭제'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Text(
      title,
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8B5A6B),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Widget trailing,
        VoidCallback? onTap,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Color(0xFFFFE7B0).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFECA666), width: 1),
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
            trailing,
          ],
        ),
      ),
    );
  }
}