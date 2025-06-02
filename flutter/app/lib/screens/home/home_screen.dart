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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // ⭐ 인증 확인
  Future<void> _checkAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    setState(() {
      _isLoading = false;
    });

    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ⭐ 로그아웃 기능
  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ 로딩 중이면 로딩 화면 표시
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 더 안전한 비율 기반 크기 (화면이 작아도 대응)
    final cardHeight = screenHeight * 0.22; // 25% -> 22%로 줄임
    final iconSizeLarge = screenWidth * 0.25; // 35% -> 25%로 줄임
    final iconSizeSmall = screenWidth * 0.22; // 30% -> 22%로 줄임
    final topLogoHeight = screenHeight * 0.28; // 20% -> 28%로 크게 증가 (로고 크기 더 증가)
    final loveIconLeftOffset = screenWidth * 0.75; // 80% -> 75%로 조정
    final cloudIconSize = screenWidth * 0.20; // 25% -> 20%로 줄임
    final cloudIconRightOffset = screenWidth * 0.15; // 5% -> 15%로 증가 (더 왼쪽으로)

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView( // 스크롤 가능하도록 추가
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 80, // BottomNavigationBar를 위한 여백
              ),
              child: Column(
                children: [
                  // ⭐ 상단 로고 (로그아웃 기능 추가)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.00,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: screenWidth * 0.06), // 프로필 아이콘과 균형
                        Flexible( // 로고가 넘치지 않도록 Flexible 추가
                          child: Image.asset(
                            'assets/logo.png',
                            height: topLogoHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // ⭐ 프로필 아이콘을 PopupMenuButton으로 변경 (로그아웃 기능 추가)
                        PopupMenuButton(
                          icon: Image.asset(
                            'assets/profile_icon.png',
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                          ),
                          itemBuilder: (context) => [
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
                                  Icon(Icons.logout, size: 20),
                                  SizedBox(width: 8),
                                  Text('로그아웃'),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('로그아웃'),
                                      content: const Text('정말 로그아웃하시겠습니까?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
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

                  // D-day 텍스트
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'D-day -100',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF3B2D2C),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 카드 2개 행
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: cardHeight,
                            child: SquareCard(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E97FD), Color(0xFF6B73FF)], // ⭐ 보라색 그라데이션
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              iconPath: 'assets/rabbit.png',
                              iconSize: iconSizeLarge,
                              iconTopOffset: -iconSizeLarge / 3, // 더 작게 조정
                              title: '동화세상',
                              subtitle: '마음을 담은, \n나만의 동화',
                              onPressed: () => Navigator.pushNamed(context, '/stories'),
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
                                colors: [Color(0xFFFFD3A8), Color(0xFFFFB84D)], // ⭐ 오렌지색 그라데이션
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              iconPath: 'assets/coloring_bear.png',
                              iconSize: iconSizeSmall,
                              iconTopOffset: -iconSizeSmall / 3, // 더 작게 조정
                              title: '색칠공부',
                              subtitle: '색칠하며 펼쳐지는 \n상상의 세계',
                              onPressed: () => Navigator.pushNamed(context, '/coloring'),
                              buttonAlignment: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // 우리의 기록일지 배너
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: SizedBox(
                      height: screenHeight * 0.12, // 10% -> 12%로 증가
                      child: WideCard(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9F8D), Color(0xFFFF6B9D)], // ⭐ 핑크-코랄 그라데이션
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        iconPath: 'assets/love.png',
                        title: '우리의 기록일지',
                        subtitle: '사랑스러운 동화, 함께 나눠요',
                        buttonText: 'START',
                        onPressed: () => Navigator.pushNamed(context, '/share'),
                        iconSize: screenWidth * 0.15, // 18% -> 15%로 줄임
                        iconTopOffset: -(screenWidth * 0.15) / 3, // 더 작게 조정
                        iconLeftOffset: loveIconLeftOffset,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Sleep Music 배너
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: SizedBox(
                      height: screenHeight * 0.12, // 10% -> 12%로 증가 (우리의 기록일지와 동일)
                      child: DarkCard(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF555B6E), Color(0xFF3A4160)], // ⭐ 다크 블루 그라데이션
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        iconPath: 'assets/cloud.png',
                        title: 'Sleep Music',
                        subtitle: '마음을 편안하게 해주는 수면 음악',
                        onPressed: () => Navigator.pushNamed(context, '/lullaby'),
                        iconSize: cloudIconSize,
                        iconTopOffset: -cloudIconSize / 3, // 더 작게 조정
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFF6B756),
        unselectedItemColor: const Color(0xFF9E9E9E),
        onTap: (index) {
          final routes = ['/home', '/stories', '/coloring', '/share', '/lullaby'];
          final currentRoute = ModalRoute.of(context)?.settings.name;

          // ⭐ 현재 페이지가 아닌 경우에만 이동
          if (currentRoute != routes[index]) {
            // Home이 아닌 페이지로 이동할 때는 pushNamed 사용
            if (index != 0) {
              Navigator.pushNamed(context, routes[index]);
            } else {
              // Home으로 돌아갈 때는 스택을 정리하며 이동
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
          BottomNavigationBarItem(icon: Icon(Icons.nights_stay), label: 'Lullabies'),
        ],
      ),
    );
  }
}

/// 카드 위젯 (전체 클릭 가능하고 START 버튼도 유지) - ⭐ 그라데이션 적용
class SquareCard extends StatelessWidget {
  final LinearGradient gradient; // ⭐ Color -> LinearGradient로 변경
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final Alignment buttonAlignment;

  const SquareCard({
    required this.gradient, // ⭐ color -> gradient로 변경
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onPressed, // 카드 전체 클릭 가능
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: iconTopOffset + iconSize / 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient, // ⭐ 그라데이션 적용
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15), // ⭐ 그림자 강화
                        blurRadius: 12, // ⭐ 블러 반경 증가
                        offset: Offset(0, 6), // ⭐ 오프셋 증가
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(12, iconSize / 2 - 4, 12, 12), // 상단 패딩을 더 줄여서 글씨를 위로
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16, // 텍스트가 안짤리도록 크기 유지
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        ),
                        overflow: TextOverflow.visible, // 짤림 방지
                        softWrap: true,
                      ),
                      const SizedBox(height: 2), // 4에서 2로 줄임
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                              fontSize: 11, // 10 -> 11로 약간 증가
                              color: Colors.white70
                          ),
                          overflow: TextOverflow.visible, // 짤림 방지
                          softWrap: true,
                          maxLines: 2, // 3에서 2로 다시 줄임
                        ),
                      ),
                      const SizedBox(height: 4), // 8에서 4로 줄임
                      // START 버튼 복원
                      Align(
                        alignment: buttonAlignment,
                        child: ElevatedButton(
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, // 24 -> 16으로 축소
                                vertical: 6 // 8 -> 6으로 축소
                            ),
                            elevation: 2, // ⭐ 버튼에도 약간의 그림자
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                              'START',
                              style: TextStyle(
                                color: gradient.colors.first, // ⭐ 그라데이션 첫 번째 색상 사용
                                fontWeight: FontWeight.bold,
                                fontSize: 12, // 폰트 크기 명시
                              )
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
                      fit: BoxFit.contain
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 넓은 배너 카드 (전체 클릭 가능하도록 개선) - ⭐ 그라데이션 적용
class WideCard extends StatelessWidget {
  final LinearGradient gradient; // ⭐ Color -> LinearGradient로 변경
  final String iconPath;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconLeftOffset;

  const WideCard({
    required this.gradient, // ⭐ color -> gradient로 변경
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    required this.iconSize,
    required this.iconTopOffset,
    required this.iconLeftOffset,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed, // 카드 전체 클릭 가능
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: iconTopOffset + iconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient, // ⭐ 그라데이션 적용
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), // ⭐ 그림자 강화
                    blurRadius: 12, // ⭐ 블러 반경 증가
                    offset: Offset(0, 6), // ⭐ 오프셋 증가
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // vertical 패딩 추가
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
                            fontSize: 15, // 14 -> 15로 증가
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.visible, // 짤림 방지
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11, // 10 -> 11로 증가
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.visible, // 짤림 방지
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // START 버튼 복원
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, // 24 -> 16으로 축소
                          vertical: 6 // 8 -> 6으로 축소
                      ),
                      elevation: 2, // ⭐ 버튼에도 약간의 그림자
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: gradient.colors.first, // ⭐ 그라데이션 첫 번째 색상 사용
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: iconTopOffset,
            left: iconLeftOffset,
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

/// 다크 배너 카드 (전체 클릭 가능하도록 개선) - ⭐ 그라데이션 적용
class DarkCard extends StatelessWidget {
  final LinearGradient gradient; // ⭐ Color -> LinearGradient로 변경
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconRightOffset;
  final bool showButton;

  const DarkCard({
    required this.gradient, // ⭐ color -> gradient로 변경
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
      onTap: onPressed, // 카드 전체 클릭 가능
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: iconTopOffset + iconSize / 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient, // ⭐ 그라데이션 적용
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), // ⭐ 그림자 강화
                    blurRadius: 12, // ⭐ 블러 반경 증가
                    offset: Offset(0, 6), // ⭐ 오프셋 증가
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // vertical 패딩 추가
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
                            fontSize: 15, // 14 -> 15로 증가
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.visible, // 짤림 방지
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11, // 10 -> 11로 증가
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.visible, // 짤림 방지
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
                            borderRadius: BorderRadius.circular(20)
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, // 24 -> 16으로 축소
                            vertical: 6 // 8 -> 6으로 축소
                        ),
                        elevation: 2, // ⭐ 버튼에도 약간의 그림자
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'START',
                        style: TextStyle(
                          color: gradient.colors.first, // ⭐ 그라데이션 첫 번째 색상 사용
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