import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../service/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _ddayText = 'D-day';
  Map<String, dynamic>? _childData;

  @override
  void initState() {
    super.initState();
    _initializeHomeScreen();
  }

  // ⭐ 홈화면 초기화 (인증 확인 + 아이 정보 로드)
  Future<void> _initializeHomeScreen() async {
    try {
      // 1. 로그인 확인
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // 2. 아이 정보 확인
      final childInfo = await AuthService.checkChildInfo();
      if (childInfo != null && childInfo['hasChild'] == true) {
        setState(() {
          _childData = childInfo['childData'];
          _ddayText = _calculateDDay(_childData);
        });
      } else {
        // 아이 정보가 없으면 아이 정보 입력 화면으로
        Navigator.pushReplacementNamed(context, '/child-info');
        return;
      }
    } catch (e) {
      print('❌ [HomeScreen] 초기화 오류: $e');
      // 오류 시 기본 텍스트 유지
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ⭐ D-day 계산 함수
  String _calculateDDay(Map<String, dynamic>? childData) {
    if (childData == null) return 'D-day';

    try {
      final babyName = childData['name'] ?? '아이';
      final birthDateStr = childData['birthDate'] ?? childData['baby_birth_date'];

      if (birthDateStr == null) {
        print('❌ [HomeScreen] 생년월일 정보 없음');
        return 'D-day';
      }

      print('🔍 [HomeScreen] 아이 정보: 이름=$babyName, 생년월일=$birthDateStr');

      // 날짜 파싱
      DateTime birthDate;
      if (birthDateStr is String) {
        birthDate = DateTime.parse(birthDateStr);
      } else {
        birthDate = birthDateStr as DateTime;
      }

      // 오늘 날짜
      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);
      final birthDateWithoutTime = DateTime(birthDate.year, birthDate.month, birthDate.day);

      // 날짜 차이 계산
      final difference = birthDateWithoutTime.difference(todayWithoutTime).inDays;

      if (difference > 0) {
        // 미래 = 아직 태어나지 않음
        return '$babyName -${difference}日';
      } else if (difference < 0) {
        // 과거 = 이미 태어남
        return '$babyName +${difference.abs()}日';
      } else {
        // 오늘 = 생일
        return '$babyName 생일! 🎉';
      }
    } catch (e) {
      print('❌ [HomeScreen] D-day 계산 오류: $e');
      return 'D-day';
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ⭐ 새로고침 함수 (pull to refresh용)
  Future<void> _refreshData() async {
    await _initializeHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_image.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF6B756)),
                ),
                SizedBox(height: 16),
                Text(
                  '로딩 중...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3B2D2C),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.22;
    final iconSizeLarge = screenWidth * 0.25;
    final iconSizeSmall = screenWidth * 0.22;
    final topLogoHeight = screenHeight * 0.28;
    final cloudIconSize = screenWidth * 0.20;
    final cloudIconRightOffset = screenWidth * 0.15;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFFF6B756),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    // 상단 로고
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.00,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: screenWidth * 0.06),
                          Flexible(
                            child: Image.asset(
                              'assets/logo.png',
                              height: topLogoHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                          PopupMenuButton(
                            icon: Image.asset(
                              'assets/profile_icon.png',
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                            ),
                            itemBuilder:
                                (context) => [
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.person, size: 20),
                                    SizedBox(width: 8),
                                    Text('프로필'),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(),
                                      ),
                                    );
                                  });
                                },
                              ),
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.refresh, size: 20),
                                    SizedBox(width: 8),
                                    Text('새로고침'),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    _refreshData();
                                  });
                                },
                              ),
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.logout, size: 20),
                                    SizedBox(width: 8),
                                    Text('로그아웃'),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(Duration.zero, () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => AlertDialog(
                                        title: const Text('로그아웃'),
                                        content: const Text(
                                          '정말 로그아웃하시겠습니까?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                              context,
                                            ),
                                            child: const Text('취소'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _logout();
                                            },
                                            child: const Text('로그아웃'),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ⭐ D-day 텍스트 (동적으로 계산됨)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.005,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              _ddayText,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF3B2D2C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // 카드 2개 행 (동화세상, 색칠공부)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: cardHeight,
                              child: SquareCard(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8E97FD), Color(0xFF6B73FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                iconPath: 'assets/rabbit.png',
                                iconSize: iconSizeLarge,
                                iconTopOffset: -iconSizeLarge / 3,
                                title: '동화세상',
                                subtitle: '마음을 담은, \n나만의 동화',
                                onPressed:
                                    () =>
                                    Navigator.pushNamed(context, '/stories'),
                                buttonAlignment: Alignment.centerRight,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: SizedBox(
                              height: cardHeight,
                              child: SquareCard(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD3A8), Color(0xFFFFB84D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                iconPath: 'assets/coloring_bear.png',
                                iconSize: iconSizeSmall,
                                iconTopOffset: -iconSizeSmall / 3,
                                title: '색칠공부',
                                subtitle: '색칠하며 펼쳐지는 \n상상의 세계',
                                onPressed:
                                    () =>
                                    Navigator.pushNamed(context, '/coloring'),
                                buttonAlignment: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // 우리의 기록일지 + 갤러리 배너 (가로 배치)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        children: [
                          // 우리의 기록일지
                          Expanded(
                            child: SizedBox(
                              height: screenHeight * 0.12,
                              child: MediumCard(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9F8D), Color(0xFFFF6B9D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                iconPath: 'assets/love.png',
                                title: '우리의 기록일지',
                                subtitle: '사랑스러운 동화\n함께 나눠요',
                                onPressed:
                                    () => Navigator.pushNamed(context, '/share'),
                                iconSize: screenWidth * 0.12,
                                iconTopOffset: -(screenWidth * 0.12) / 3,
                                iconRightOffset: screenWidth * 0.02,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          // 갤러리
                          Expanded(
                            child: SizedBox(
                              height: screenHeight * 0.12,
                              child: MediumCard(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                iconPath: '', // 빈 문자열 (사용하지 않음)
                                title: '갤러리',
                                subtitle: '아름다운 순간들을\n모아보세요',
                                onPressed:
                                    () =>
                                    Navigator.pushNamed(context, '/gallery'),
                                iconSize: screenWidth * 0.12,
                                iconTopOffset: -(screenWidth * 0.12) / 3,
                                iconRightOffset: screenWidth * 0.02,
                                useIconWidget: true, // Icon 위젯 사용
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Sleep Music 배너
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: SizedBox(
                        height: screenHeight * 0.12,
                        child: DarkCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF555B6E), Color(0xFF3A4160)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconPath: 'assets/cloud.png',
                          title: 'Sleep Music',
                          subtitle: '마음을 편안하게 해주는 수면 음악',
                          onPressed:
                              () => Navigator.pushNamed(context, '/lullaby'),
                          iconSize: cloudIconSize,
                          iconTopOffset: -cloudIconSize / 3,
                          iconRightOffset: cloudIconRightOffset,
                          showButton: true,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFF6B756),
        unselectedItemColor: const Color(0xFF9E9E9E),
        onTap: (index) {
          final routes = [
            '/home',
            '/stories',
            '/coloring',
            '/share',
            '/lullaby',
            '/gallery',
          ];
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != routes[index]) {
            if (index != 0) {
              Navigator.pushNamed(context, routes[index]);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                    (route) => false,
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Stories'),
          BottomNavigationBarItem(icon: Icon(Icons.brush), label: 'Coloring'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Share'),
          BottomNavigationBarItem(
            icon: Icon(Icons.nights_stay),
            label: 'Lullabies',
          ),
        ],
      ),
    );
  }
}

// SquareCard 위젯
class SquareCard extends StatelessWidget {
  final LinearGradient gradient;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final Alignment buttonAlignment;

  const SquareCard({
    required this.gradient,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.iconSize,
    required this.iconTopOffset,
    required this.buttonAlignment,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: iconTopOffset + iconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(12, iconSize / 2 - 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: buttonAlignment,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 2,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: gradient.colors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: iconTopOffset,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MediumCard 위젯 (우리의 기록일지 + 갤러리용)
class MediumCard extends StatelessWidget {
  final LinearGradient gradient;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconRightOffset;
  final bool useIconWidget; // 새로 추가

  const MediumCard({
    required this.gradient,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.iconSize,
    required this.iconTopOffset,
    required this.iconRightOffset,
    this.useIconWidget = false, // 기본값 false
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: iconTopOffset + iconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        elevation: 2,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: gradient.colors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: iconTopOffset,
            right: iconRightOffset,
            child:
            useIconWidget
                ? Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
            )
                : Image.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// DarkCard 위젯
class DarkCard extends StatelessWidget {
  final LinearGradient gradient;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconRightOffset;
  final bool showButton;

  const DarkCard({
    required this.gradient,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.iconSize,
    required this.iconTopOffset,
    required this.iconRightOffset,
    this.showButton = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: iconTopOffset + iconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  if (showButton) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 2,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: gradient.colors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: iconTopOffset,
            right: iconRightOffset,
            child: Image.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}