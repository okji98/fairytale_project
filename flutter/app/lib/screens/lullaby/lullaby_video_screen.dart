// lib/screens/lullaby/lullaby_video_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'video_player_screen.dart';
import '../../models/lullaby_models.dart';

class LullabyVideoScreen extends StatefulWidget {
  const LullabyVideoScreen({super.key});

  @override
  State<LullabyVideoScreen> createState() => _LullabyVideoScreenState();
}

class _LullabyVideoScreenState extends State<LullabyVideoScreen> {
  // Spring Boot 서버 설정
  static const String baseUrl = 'http://localhost:8080';
  static const String videoListEndpoint = '/api/lullaby/videos';
  static const String recommendEndpoint = '/api/lullaby/recommend';

  List<LullabyVideoTheme> _videoThemes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // 사용자 선호도 저장 (로컬 상태)
  Map<String, int> _userPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadVideoThemes();
  }

  // Spring Boot에서 비디오 목록 가져오기
  Future<void> _loadVideoThemes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http
          .get(
            Uri.parse('$baseUrl$videoListEndpoint'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(responseBody);

        setState(() {
          _videoThemes =
              data.map((item) => LullabyVideoTheme.fromJson(item)).toList();
          _isLoading = false;
        });

        // 사용자 맞춤 추천 받기
        _getRecommendations();
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '비디오 목록을 불러올 수 없습니다: $e';
        _isLoading = false;
        // 오프라인 모드: 기본 데이터 사용
        _loadOfflineData();
      });
    }
  }

  // AI 기반 추천 받기
  Future<void> _getRecommendations() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$recommendEndpoint'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userId': 'user123', // 실제로는 로그인한 사용자 ID
          'preferences': _userPreferences,
          'timeOfDay': DateTime.now().hour,
          'recentlyPlayed': _getRecentlyPlayedIds(),
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final recommendations = jsonDecode(responseBody);

        // 추천 순서대로 비디오 정렬
        if (recommendations['recommendedOrder'] != null) {
          _sortVideosByRecommendation(recommendations['recommendedOrder']);
        }
      }
    } catch (e) {
      print('추천 받기 실패: $e');
    }
  }

  // 최근 재생한 비디오 ID 가져오기
  List<String> _getRecentlyPlayedIds() {
    // 실제로는 SharedPreferences나 로컬 DB에서 가져와야 함
    return [];
  }

  // 추천 순서대로 정렬
  void _sortVideosByRecommendation(List<dynamic> recommendedIds) {
    setState(() {
      _videoThemes.sort((a, b) {
        final aIndex = recommendedIds.indexOf(a.id);
        final bIndex = recommendedIds.indexOf(b.id);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
    });
  }

  // 오프라인 모드용 기본 데이터
  void _loadOfflineData() {
    _videoThemes = [
      LullabyVideoTheme(
        id: '1',
        title: '잔잔한 피아노',
        icon: Icons.piano,
        color: const Color(0xFF6B73FF),
        youtubeId: 'dQw4w9WgXcQ',
        description: '부드러운 피아노 선율과 함께하는 시각적 휴식',
        duration: '30분',
        thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      ),
      // ... 나머지 기본 데이터
    ];
  }

  // 비디오 재생 및 통계 전송
  Future<void> _playVideo(LullabyVideoTheme theme) async {
    // 재생 통계 Spring Boot로 전송
    _sendPlayStatistics(theme);

    // 사용자 선호도 업데이트
    setState(() {
      _userPreferences[theme.id] = (_userPreferences[theme.id] ?? 0) + 1;
    });

    // 비디오 플레이어 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoPlayerScreen(theme: theme)),
    );

    // 재생 완료 후 피드백 처리
    if (result != null && result is Map<String, dynamic>) {
      _sendFeedback(theme.id, result);
    }
  }

  // 재생 통계 전송
  Future<void> _sendPlayStatistics(LullabyVideoTheme theme) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/lullaby/play-stats'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': theme.id,
          'userId': 'user123',
          'timestamp': DateTime.now().toIso8601String(),
          'deviceInfo': {'platform': 'flutter', 'version': '1.0.0'},
        }),
      );
    } catch (e) {
      print('통계 전송 실패: $e');
    }
  }

  // 사용자 피드백 전송
  Future<void> _sendFeedback(
    String videoId,
    Map<String, dynamic> feedback,
  ) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/lullaby/feedback'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': videoId,
          'userId': 'user123',
          'feedback': feedback,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('피드백 전송 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_sleep_main.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar 영역
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
                    const Spacer(),
                    // 새로고침 버튼
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadVideoThemes,
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

                      // 로딩, 에러, 컨텐츠 표시
                      Expanded(
                        child:
                            _isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                                : _errorMessage.isNotEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadVideoThemes,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withOpacity(0.2),
                                        ),
                                        child: const Text('다시 시도'),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: _videoThemes.length,
                                  itemBuilder: (context, index) {
                                    final theme = _videoThemes[index];
                                    return _buildVideoCard(theme, index == 0);
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

  Widget _buildVideoCard(LullabyVideoTheme theme, bool isRecommended) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isRecommended
                  ? theme.color.withOpacity(0.6)
                  : Colors.white.withOpacity(0.2),
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 추천 배지
          if (isRecommended)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '추천',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Column(
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
                      child: Icon(theme.icon, color: Colors.white, size: 24),
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
                          if (_userPreferences[theme.id] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_userPreferences[theme.id]}회 재생됨',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
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
        ],
      ),
    );
  }
}
