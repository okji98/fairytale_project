// lib/screens/lullaby/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/lullaby_models.dart'; // ⭐ 기존 모델 파일 임포트

class VideoPlayerScreen extends StatefulWidget {
  final LullabyVideoTheme theme;

  const VideoPlayerScreen({super.key, required this.theme});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // TODO: YouTube API 연동 - 실제 자장가 영상 ID로 교체 필요
    _controller = YoutubePlayerController(
      initialVideoId: widget.theme.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                      Row(
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
                      const SizedBox(height: 30),
                      const Text(
                        '편안한 휴식을 위한 팁',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTipItem('조명을 어둡게 하고 편안한 자세를 취하세요'),
                      _buildTipItem('깊고 천천히 호흡하며 긴장을 풀어보세요'),
                      _buildTipItem('휴대폰은 멀리 두고 온전히 휴식에 집중하세요'),
                      _buildTipItem('영상과 함께 마음을 비우고 평온함을 느껴보세요'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: widget.theme.color,
              borderRadius: BorderRadius.circular(3),
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
}
