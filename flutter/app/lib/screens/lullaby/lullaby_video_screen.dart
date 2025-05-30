// lib/screens/lullaby/lullaby_video_screen.dart
import 'package:flutter/material.dart';
import 'video_player_screen.dart'; // ⭐ 주석 해제
import '../../models/lullaby_models.dart'; // ⭐ 기존 모델 파일 임포트

class LullabyVideoScreen extends StatefulWidget {
  const LullabyVideoScreen({super.key});

  @override
  State<LullabyVideoScreen> createState() => _LullabyVideoScreenState();
}

class _LullabyVideoScreenState extends State<LullabyVideoScreen> {
  // 자장가 영상 테마 데이터
  final List<LullabyVideoTheme> _videoThemes = [
    LullabyVideoTheme(
      title: '잔잔한 피아노',
      icon: Icons.piano,
      color: const Color(0xFF6B73FF),
      youtubeId: 'dQw4w9WgXcQ', // TODO: 실제 자장가 영상 ID로 교체
      description: '부드러운 피아노 선율과 함께하는 시각적 휴식',
      duration: '30분',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    ),
    LullabyVideoTheme(
      title: '기타 멜로디',
      icon: Icons.music_note,
      color: const Color(0xFF9B59B6),
      youtubeId: 'dQw4w9WgXcQ', // TODO: 실제 자장가 영상 ID로 교체
      description: '따뜻한 기타 선율과 아름다운 자연 영상',
      duration: '45분',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    ),
    LullabyVideoTheme(
      title: '자연의 소리',
      icon: Icons.eco,
      color: const Color(0xFF27AE60),
      youtubeId: 'dQw4w9WgXcQ', // TODO: 실제 자장가 영상 ID로 교체
      description: '새소리와 물소리, 자연의 아름다운 풍경',
      duration: '60분',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    ),
    LullabyVideoTheme(
      title: '달빛',
      icon: Icons.nightlight,
      color: const Color(0xFFF39C12),
      youtubeId: 'dQw4w9WgXcQ', // TODO: 실제 자장가 영상 ID로 교체
      description: '달빛이 비치는 고요한 밤의 풍경',
      duration: '40분',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    ),
    LullabyVideoTheme(
      title: '하늘',
      icon: Icons.cloud,
      color: const Color(0xFF3498DB),
      youtubeId: 'dQw4w9WgXcQ', // TODO: 실제 자장가 영상 ID로 교체
      description: '구름이 흘러가는 평화로운 하늘',
      duration: '35분',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    ),
    LullabyVideoTheme(
      title: '클래식',
      icon: Icons.library_music,
      color: const Color(0xFFE74C3C),
      youtubeId: 'dQw4w9WgXcQ', // TODO: 실제 자장가 영상 ID로 교체
      description: '클래식 음악과 함께하는 예술적 영상',
      duration: '50분',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
    ),
  ];

  void _playVideo(LullabyVideoTheme theme) {
    // ⭐ 비디오 플레이어 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(theme: theme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_sleep_main.png'), // ⭐ 배경 이미지 추가
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar 영역을 직접 구현
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '자장가 영상',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 메인 컨텐츠
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '편안한 영상을 선택해주세요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '시각적 효과와 함께 더욱 깊은 휴식을 경험하세요',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _videoThemes.length,
                          itemBuilder: (context, index) {
                            final theme = _videoThemes[index];
                            return _buildVideoCard(theme);
                          },
                        ),
                      ),
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

  Widget _buildVideoCard(LullabyVideoTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // ⭐ 배경 이미지와 어우러지도록 투명도 조정
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // ⭐ 그림자 투명도 조정
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 썸네일 영역
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [
                  theme.color.withOpacity(0.8),
                  theme.color.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                // 재생 버튼과 아이콘
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          theme.icon,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _playVideo(theme),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: theme.color,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 시간 표시
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      theme.duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 정보 영역
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.color.withOpacity(0.8),
                        theme.color.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    theme.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _playVideo(theme),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.color,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}