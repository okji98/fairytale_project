// lib/screens/lullaby/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../models/lullaby_models.dart';

class VideoPlayerScreen extends StatefulWidget {
  final LullabyVideoTheme theme;

  const VideoPlayerScreen({super.key, required this.theme});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  // Spring Boot 서버 설정
  static const String baseUrl = 'http://localhost:8080';

  // 재생 시간 추적
  DateTime? _playStartTime;
  Duration _totalWatchTime = Duration.zero;
  Timer? _watchTimer;

  // 사용자 피드백
  int? _userRating;
  bool _helpedSleep = false;
  final TextEditingController _feedbackController = TextEditingController();

  // AI 기반 팁
  List<String> _personalizedTips = [];
  bool _tipsLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadPersonalizedTips();
    _startWatchTracking();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.theme.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        enableCaption: false,
        forceHD: true, // HD 화질 강제
      ),
    );

    // 플레이어 상태 리스너
    _controller.addListener(() {
      if (_controller.value.isPlaying && _playStartTime == null) {
        _playStartTime = DateTime.now();
      }
    });
  }

  // AI 기반 개인화된 팁 로드
  Future<void> _loadPersonalizedTips() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lullaby/tips'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': widget.theme.id,
          'userId': 'user123',
          'timeOfDay': DateTime.now().hour,
          'category': widget.theme.title,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        setState(() {
          _personalizedTips = List<String>.from(data['tips'] ?? []);
          _tipsLoading = false;
        });
      } else {
        _useDefaultTips();
      }
    } catch (e) {
      print('팁 로드 실패: $e');
      _useDefaultTips();
    }
  }

  void _useDefaultTips() {
    setState(() {
      _personalizedTips = [
        '조명을 어둡게 하고 편안한 자세를 취하세요',
        '깊고 천천히 호흡하며 긴장을 풀어보세요',
        '휴대폰은 멀리 두고 온전히 휴식에 집중하세요',
        '영상과 함께 마음을 비우고 평온함을 느껴보세요',
      ];
      _tipsLoading = false;
    });
  }

  // 시청 시간 추적
  void _startWatchTracking() {
    _watchTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_controller.value.isPlaying) {
        setState(() {
          _totalWatchTime += const Duration(seconds: 10);
        });
        _sendWatchProgress();
      }
    });
  }

  // 시청 진행 상황 전송
  Future<void> _sendWatchProgress() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/lullaby/watch-progress'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': widget.theme.id,
          'userId': 'user123',
          'watchTime': _totalWatchTime.inSeconds,
          'currentPosition': _controller.value.position.inSeconds,
          'totalDuration': _controller.metadata.duration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('진행 상황 전송 실패: $e');
    }
  }

  // 피드백 다이얼로그
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('영상은 어떠셨나요?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('평점을 선택해주세요'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < (_userRating ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              _userRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      title: const Text('수면에 도움이 되었나요?'),
                      value: _helpedSleep,
                      onChanged: (value) {
                        setState(() {
                          _helpedSleep = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '추가 의견을 남겨주세요 (선택)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _submitFeedback();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop({
                      'rating': _userRating,
                      'helpedSleep': _helpedSleep,
                      'comment': _feedbackController.text,
                    });
                  },
                  child: const Text('제출'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 피드백 제출
  Future<void> _submitFeedback() async {
    if (_userRating == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/api/lullaby/feedback'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': widget.theme.id,
          'userId': 'user123',
          'rating': _userRating,
          'helpedSleep': _helpedSleep,
          'comment': _feedbackController.text,
          'watchTime': _totalWatchTime.inSeconds,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.theme.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback),
            onPressed: _showFeedbackDialog,
            tooltip: '피드백 남기기',
          ),
        ],
      ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: widget.theme.color,
          progressColors: ProgressBarColors(
            playedColor: widget.theme.color,
            handleColor: widget.theme.color,
          ),
          bottomActions: [
            CurrentPosition(),
            const SizedBox(width: 10),
            ProgressBar(isExpanded: true),
            const SizedBox(width: 10),
            RemainingDuration(),
            FullScreenButton(),
          ],
        ),
        builder: (context, player) {
          return Column(
            children: [
              player,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 비디오 정보 카드
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.theme.color.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.theme.color.withOpacity(0.8),
                                    widget.theme.color.withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.theme.icon,
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
                                    widget.theme.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.theme.description,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 시청 시간 표시
                      if (_totalWatchTime.inSeconds > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.theme.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '시청 시간: ${_formatDuration(_totalWatchTime)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // 개인화된 팁 섹션
                      const Text(
                        '편안한 휴식을 위한 맞춤 팁',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_tipsLoading)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _personalizedTips.length,
                            itemBuilder: (context, index) {
                              return _buildTipItem(
                                _personalizedTips[index],
                                index,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 하단 컨트롤 바
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  border: Border(
                    top: BorderSide(color: widget.theme.color.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.brightness_6,
                      label: '화면 밝기',
                      onTap: () => _adjustBrightness(),
                    ),
                    _buildControlButton(
                      icon: Icons.volume_up,
                      label: '볼륨 조절',
                      onTap: () => _showVolumeControl(),
                    ),
                    _buildControlButton(
                      icon: Icons.timer,
                      label: '타이머',
                      onTap: () => _showTimerDialog(),
                    ),
                    _buildControlButton(
                      icon: Icons.favorite_border,
                      label: '저장',
                      onTap: () => _saveToFavorites(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTipItem(String tip, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.theme.color.withOpacity(0.8),
                  widget.theme.color.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.theme.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.theme.color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // 화면 밝기 조절
  void _adjustBrightness() {
    // 실제 구현시 screen_brightness 패키지 사용
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('화면 밝기 조절 기능')));
  }

  // 볼륨 컨트롤 표시
  void _showVolumeControl() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) {
        double volume = _controller.value.volume * 100;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '볼륨 조절',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: volume,
                    min: 0,
                    max: 100,
                    activeColor: widget.theme.color,
                    onChanged: (value) {
                      setState(() {
                        volume = value;
                        _controller.setVolume((value / 100) as int);
                      });
                    },
                  ),
                  Text(
                    '${volume.round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 타이머 다이얼로그
  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('취침 타이머'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('15분'), onTap: () => _setTimer(15)),
              ListTile(title: const Text('30분'), onTap: () => _setTimer(30)),
              ListTile(title: const Text('45분'), onTap: () => _setTimer(45)),
              ListTile(title: const Text('60분'), onTap: () => _setTimer(60)),
            ],
          ),
        );
      },
    );
  }

  // 타이머 설정
  void _setTimer(int minutes) {
    Navigator.of(context).pop();
    Timer(Duration(minutes: minutes), () {
      _controller.pause();
      _showFeedbackDialog();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$minutes분 후에 자동으로 종료됩니다')));
  }

  // 즐겨찾기 저장
  Future<void> _saveToFavorites() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lullaby/favorites'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': widget.theme.id,
          'userId': 'user123',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('즐겨찾기에 추가되었습니다')));
      }
    } catch (e) {
      print('즐겨찾기 저장 실패: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _watchTimer?.cancel();
    _feedbackController.dispose();

    // 최종 시청 통계 전송
    if (_totalWatchTime.inSeconds > 0) {
      _sendFinalStats();
    }

    super.dispose();
  }

  // 최종 통계 전송
  Future<void> _sendFinalStats() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/lullaby/session-end'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'videoId': widget.theme.id,
          'userId': 'user123',
          'totalWatchTime': _totalWatchTime.inSeconds,
          'completionRate':
              _controller.value.position.inSeconds /
              _controller.metadata.duration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('최종 통계 전송 실패: $e');
    }
  }
}
