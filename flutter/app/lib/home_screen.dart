import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 비율 기반 크기
    final cardHeight = screenHeight * 0.25;
    final iconSizeLarge = screenWidth * 0.35;
    final iconSizeSmall = screenWidth * 0.30;
    final topLogoHeight = screenHeight * 0.28;
    final loveIconLeftOffset = screenWidth * 0.80;
    final cloudIconSize = screenWidth * 0.25;
    final cloudIconRightOffset = screenWidth * 0.10;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 로고
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: screenWidth * 0.03),
                    Image.asset('assets/logo.png', height: topLogoHeight),
                    IconButton(
                      icon: Image.asset(
                        'assets/profile_icon.png',
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // TODO: D-day API 연동
              Transform.translate(
                offset: Offset(0, -screenHeight * 0.07),
                child: Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.04),
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
                          color: const Color(0xFF8E97FD),
                          iconPath: 'assets/rabbit.png',
                          iconSize: iconSizeLarge,
                          iconTopOffset: -iconSizeLarge / 2,
                          title: '동화세상',
                          subtitle: '마음을 담아, 나만의 동화를 지어요',
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
                          color: const Color(0xFFFFD3A8),
                          iconPath: 'assets/coloring_bear.png',
                          iconSize: iconSizeSmall,
                          iconTopOffset: -iconSizeSmall / 2,
                          title: '색칠공부',
                          subtitle: '색칠하며 펼쳐지는 상상의 세계',
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
                  height: screenHeight * 0.12,
                  child: WideCard(
                    color: const Color(0xFFFF9F8D),
                    iconPath: 'assets/love.png',
                    title: '우리의 기록일지',
                    subtitle: '사랑스러운 동화, 함께 나눠요',
                    buttonText: 'START',
                    onPressed: () => Navigator.pushNamed(context, '/share'),
                    iconSize: screenWidth * 0.18,
                    iconTopOffset: -(screenWidth * 0.18) / 2,
                    iconLeftOffset: loveIconLeftOffset,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Sleep Music 배너
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: SizedBox(
                  height: screenHeight * 0.12,
                  child: DarkCard(
                    color: const Color(0xFF555B6E),
                    iconPath: 'assets/cloud.png',
                    title: 'Sleep Music',
                    subtitle: '마음을 편안하게 해주는 수면 음악',
                    onPressed: () => Navigator.pushNamed(context, '/lullabies'),
                    iconSize: cloudIconSize,
                    iconTopOffset: -cloudIconSize / 2,
                    iconRightOffset: cloudIconRightOffset,
                    showButton: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: const Color(0xFFF6B756),
        unselectedItemColor: const Color(0xFF9E9E9E),
        onTap: (index) {
          final routes = ['/home', '/stories', '/coloring', '/share', '/lullabies'];
          Navigator.pushReplacementNamed(context, routes[index]);
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

/// 카드 위젯
class SquareCard extends StatelessWidget {
  final Color color;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final Alignment buttonAlignment;

  const SquareCard({
    required this.color,
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: iconTopOffset + iconSize / 2,
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.fromLTRB(16, iconSize / 2 + 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                Spacer(),
                Align(
                  alignment: buttonAlignment,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      elevation: 0,
                    ),
                    child: Text('START', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
            child: Image.asset(iconPath, width: iconSize, height: iconSize, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}


/// 넓은 배너 카드
class WideCard extends StatelessWidget {
  final Color color;
  final String iconPath;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconLeftOffset;

  const WideCard({
    required this.color,
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: iconTopOffset + iconSize / 2,
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
    );
  }
}

/// 다크 배너 카드
class DarkCard extends StatelessWidget {
  final Color color;
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final double iconSize;
  final double iconTopOffset;
  final double iconRightOffset;
  final bool showButton;

  const DarkCard({
    required this.color,
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: iconTopOffset + iconSize / 2,
          child: Container(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showButton) ...[
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      elevation: 0,
                    ),
                    child: Text(
                      'START',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
    );
  }
}
