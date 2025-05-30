// lib/models/lullaby_models.dart
import 'package:flutter/material.dart';

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

class LullabyVideoTheme {
  final String title;
  final IconData icon;
  final Color color;
  final String youtubeId;
  final String description;
  final String duration;
  final String thumbnail;

  LullabyVideoTheme({
    required this.title,
    required this.icon,
    required this.color,
    required this.youtubeId,
    required this.description,
    required this.duration,
    required this.thumbnail,
  });
}