import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class UploadBoardScreen extends StatefulWidget {
  const UploadBoardScreen({super.key});

  @override
  State<UploadBoardScreen> createState() => _UploadBoardScreenState();
}

class _UploadBoardScreenState extends State<UploadBoardScreen> {
  List<Map<String, dynamic>> posts = [];

  Future<void> _pickAndAddVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      posts.insert(0, {
        'type': 'video',
        'path': picked.path,
      });
    });
  }

  Widget _buildMediaItem(Map<String, dynamic> post) {
    return VideoWidget(filePath: post['path']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티 게시판')),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndAddVideo,
        child: const Icon(Icons.video_library),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(12.0),
          child: _buildMediaItem(posts[index]),
        ),
      ),
    );
  }
}

class VideoWidget extends StatefulWidget {
  final String filePath;
  const VideoWidget({super.key, required this.filePath});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(_controller, allowScrubbing: true),
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          )
        ],
      ),
    )
        : const CircularProgressIndicator();
  }
}
