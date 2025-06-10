// lib/models/lullaby_models.dart
import 'package:flutter/material.dart';

class LullabyVideoTheme {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String youtubeId;
  final String description;
  final String duration;
  final String thumbnail;
  final Map<String, dynamic>? metadata;

  LullabyVideoTheme({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.youtubeId,
    required this.description,
    required this.duration,
    required this.thumbnail,
    this.metadata,
  });

  // JSON에서 객체로 변환
  factory LullabyVideoTheme.fromJson(Map<String, dynamic> json) {
    return LullabyVideoTheme(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'music_note'),
      color: Color(int.parse(json['color'] ?? '0xFF6B73FF', radix: 16)),
      youtubeId: json['youtubeId'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      metadata: json['metadata'],
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': _getStringFromIcon(icon),
      'color': '0x${color.value.toRadixString(16).toUpperCase()}',
      'youtubeId': youtubeId,
      'description': description,
      'duration': duration,
      'thumbnail': thumbnail,
      'metadata': metadata,
    };
  }

  // 문자열을 IconData로 변환
  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'piano':
        return Icons.piano;
      case 'music_note':
        return Icons.music_note;
      case 'eco':
        return Icons.eco;
      case 'nightlight':
        return Icons.nightlight;
      case 'cloud':
        return Icons.cloud;
      case 'library_music':
        return Icons.library_music;
      default:
        return Icons.music_note;
    }
  }

  // IconData를 문자열로 변환
  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.piano) return 'piano';
    if (icon == Icons.music_note) return 'music_note';
    if (icon == Icons.eco) return 'eco';
    if (icon == Icons.nightlight) return 'nightlight';
    if (icon == Icons.cloud) return 'cloud';
    if (icon == Icons.library_music) return 'library_music';
    return 'music_note';
  }
}

// 사용자 피드백 모델
class VideoFeedback {
  final String videoId;
  final String userId;
  final int rating;
  final bool helpedSleep;
  final String? comment;
  final int watchTime;
  final DateTime timestamp;

  VideoFeedback({
    required this.videoId,
    required this.userId,
    required this.rating,
    required this.helpedSleep,
    this.comment,
    required this.watchTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'userId': userId,
      'rating': rating,
      'helpedSleep': helpedSleep,
      'comment': comment,
      'watchTime': watchTime,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// 시청 진행 상황 모델
class WatchProgress {
  final String videoId;
  final String userId;
  final int watchTime;
  final int currentPosition;
  final int totalDuration;
  final DateTime timestamp;

  WatchProgress({
    required this.videoId,
    required this.userId,
    required this.watchTime,
    required this.currentPosition,
    required this.totalDuration,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'userId': userId,
      'watchTime': watchTime,
      'currentPosition': currentPosition,
      'totalDuration': totalDuration,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// AI 추천 응답 모델
class VideoRecommendation {
  final List<String> recommendedOrder;
  final Map<String, double> scores;
  final String reason;

  VideoRecommendation({
    required this.recommendedOrder,
    required this.scores,
    required this.reason,
  });

  factory VideoRecommendation.fromJson(Map<String, dynamic> json) {
    return VideoRecommendation(
      recommendedOrder: List<String>.from(json['recommendedOrder'] ?? []),
      scores: Map<String, double>.from(json['scores'] ?? {}),
      reason: json['reason'] ?? '',
    );
  }
}
