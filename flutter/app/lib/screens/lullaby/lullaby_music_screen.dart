// lib/screens/lullaby/lullaby_music_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class LullabyMusicScreen extends StatefulWidget {
  const LullabyMusicScreen({super.key});

  @override
  State<LullabyMusicScreen> createState() => _LullabyMusicScreenState();
}

class _LullabyMusicScreenState extends State<LullabyMusicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPlayingTheme;
  Duration _duration = const Duration(minutes: 45); // 임시 duration
  Duration _position = const Duration(minutes: 1, seconds: 30); // 임시 position
  int _selectedThemeIndex = 0;

  // TODO: S3 연동 - 실제 S3 URL로 교체 필요
  final List<LullabyTheme> _themes = [
    LullabyTheme(
      title: 'Focus Attention',
      duration: '10 MIN',
      s3Url: 'https://your-s3-bucket.com/lullaby/focus.mp3', // TODO: 실제 S3 URL 연결
      description: '집중력 향상을 위한 잔잔한 음악',
    ),
    LullabyTheme(
      title: 'Body Scan',
      duration: '6 MIN',
      s3Url: 'https://your-s3-bucket.com/lullaby/body-scan.mp3', // TODO: 실제 S3 URL 연결
      description: '몸과 마음의 긴장을 풀어주는 음악',
    ),
    LullabyTheme(
      title: 'Making Happiness',
      duration: '3 MIN',
      s3Url: 'https://your-s3-bucket.com/lullaby/happiness.mp3', // TODO: 실제 S3 URL 연결
      description: '행복한 기분을 만들어주는 음악',
    ),
    LullabyTheme(
      title: '잔잔한 피아노',
      duration: '30 MIN',
      s3Url: 'https://your-s3-bucket.com/lullaby/piano.mp3', // TODO: 실제 S3 URL 연결
      description: '부드러운 피아노 선율',
    ),
    LullabyTheme(
      title: '기타 멜로디',
      duration: '25 MIN',
      s3Url: 'https://your-s3-bucket.com/lullaby/guitar.mp3', // TODO: 실제 S3 URL 연결
      description: '따뜻한 기타 선율',
    ),
    LullabyTheme(
      title: '자연의 소리',
      duration: '60 MIN',
      s3Url: 'https://your-s3-bucket.com/lullaby/nature.mp3', // TODO: 실제 S3 URL 연결
      description: '새소리와 물소리',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // TODO: S3 오디오 스트리밍 연동
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPlayingTheme = null;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // TODO: S3에서 실제 음악 파일 재생
      // await _audioPlayer.play(UrlSource(_themes[_selectedThemeIndex].s3Url));
      print('재생: ${_themes[_selectedThemeIndex].title}'); // 임시 로그
    }
    setState(() {
      _isPlaying = !_isPlaying;
      _currentPlayingTheme = _themes[_selectedThemeIndex].title;
    });
  }

  void _playTheme(int index) {
    setState(() {
      _selectedThemeIndex = index;
      _currentPlayingTheme = _themes[index].title;
      _isPlaying = true;
      _position = Duration.zero;
    });
    // TODO: S3에서 선택된 테마 재생
    print('테마 변경: ${_themes[index].title}'); // 임시 로그
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_sleep.png'), // 배경 이미지 변경
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 전체 컬럼 레이아웃
              Column(
                children: [
                  // 상단 헤더
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
                      ],
                    ),
                  ),

                  // 곰돌이 일러스트 영역 (상단) - 크기 조정
                  Expanded(
                    flex: 2, // ⭐ 곰돌이 영역 비율 줄임: 4 → 2 (하단 플레이어 공간 확보)
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 별들 (선택사항으로 유지)
                          Positioned(
                            top: 20,
                            left: 50,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 60,
                            right: 80,
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 하단 플레이어 영역 (음악 리스트) - 비율 증가
                  Expanded(
                    flex: 8, // ⭐ 하단 플레이어 영역 비율 크게 증가: 6 → 8
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95), // 반투명으로 변경
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 25, 30, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 80), // ⭐ 곰돌이 이미지 공간 확보

                            // 제목과 설명
                            const Text(
                              'Sleep Music',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '깊고 풍부한 음성으로 마음을 편안하게 숙면하세요',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // 플레이어 컨트롤
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 이전 버튼 (15초 뒤로)
                                GestureDetector(
                                  onTap: () {
                                    // TODO: 10초 뒤로 이동 구현
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.replay_10,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 30),
                                // 재생/일시정지 버튼
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4A4A4A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 30),
                                // 다음 버튼 (15초 앞으로)
                                GestureDetector(
                                  onTap: () {
                                    // TODO: 10초 앞으로 이동 구현
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.forward_10,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // 프로그레스 바
                            Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: const Color(0xFF6B73FF),
                                    inactiveTrackColor: Colors.grey[300],
                                    thumbColor: const Color(0xFF6B73FF),
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: _position.inSeconds.toDouble(),
                                    max: _duration.inSeconds.toDouble(),
                                    onChanged: (value) async {
                                      final position = Duration(seconds: value.toInt());
                                      // TODO: S3 오디오 시간 이동 구현
                                      await _audioPlayer.seek(position);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_position),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_duration),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // 플레이리스트 (화면의 대부분 차지)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(top: 5),
                                child: ListView.builder(
                                  itemCount: _themes.length,
                                  itemBuilder: (context, index) {
                                    final theme = _themes[index];
                                    final isSelected = _selectedThemeIndex == index;

                                    return GestureDetector(
                                      onTap: () => _playTheme(index),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF6B73FF).withOpacity(0.15)
                                              : Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(16),
                                          border: isSelected
                                              ? Border.all(
                                            color: const Color(0xFF6B73FF).withOpacity(0.4),
                                            width: 1.5,
                                          )
                                              : Border.all(
                                            color: Colors.grey.withOpacity(0.2),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFF6B73FF)
                                                    : Colors.grey[300],
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                isSelected && _isPlaying
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: isSelected ? Colors.white : Colors.grey[600],
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    theme.title,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected
                                                          ? const Color(0xFF6B73FF)
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    theme.duration,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ⭐ 곰돌이 이미지를 Stack의 최상단에 위치시켜 하단 플레이어 영역까지 침범하도록 함
              Positioned(
                top: 60, // 헤더 아래쪽에 위치
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 320, // ⭐ 곰돌이 크기 대폭 확대: 250 → 320
                    height: 320, // ⭐ 곰돌이 크기 대폭 확대: 250 → 320
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/sleep_bear.png',
                      width: 320, // ⭐ 곰돌이 크기 대폭 확대: 250 → 320
                      height: 320, // ⭐ 곰돌이 크기 대폭 확대: 250 → 320
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // 이미지 로드 실패시 대체 이모지
                        return Container(
                          width: 320, // ⭐ 곰돌이 크기 대폭 확대: 250 → 320
                          height: 320, // ⭐ 곰돌이 크기 대폭 확대: 250 → 320
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEB887),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              '🧸',
                              style: TextStyle(fontSize: 150), // 이모지도 크기 증가: 120 → 150
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LullabyTheme {
  final String title;
  final String duration;
  final String s3Url;
  final String description;

  LullabyTheme({
    required this.title,
    required this.duration,
    required this.s3Url,
    required this.description,
  });
}