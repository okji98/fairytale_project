// lib/stories_screen.dart
import 'package:flutter/material.dart';
import 'main.dart'; // For BaseScaffold

class StoriesScreen extends StatefulWidget {
  @override
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final TextEditingController _nameController = TextEditingController();
  double _speed = 1.0;
  String? _selectedTheme;
  String? _selectedVoice;
  String? _generatedStory;
  bool _isPlaying = false;
  String? _selectedImageMode; // 'color' or 'bw'

  final List<String> _themes = ['자연', '도전', '가족', '사랑', '우정', '용기'];
  final List<String> _voices = ['Voice A', 'Voice B', 'Voice C']; // TODO: replace with Google TTS voices

  void _generateStory() {
    // TODO: call API to generate story based on name, speed, theme, voice
    setState(() {
      _generatedStory = '여기에 생성된 동화 텍스트가 표시됩니다.';
    });
  }

  void _playPauseAudio() {
    // TODO: play or pause TTS audio
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _generateImage() {
    // TODO: call API to generate images (color or black/white)
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFFF6B756);
    return BaseScaffold(
      background: Image.asset(
        'assets/bg_image.png', // Stories 전용 배경
        fit: BoxFit.cover,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: back button, centered logo, rabbit overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Image.asset(
                    'assets/logo.png', // 가운데 로고 이미지
                    height: 200,
                  ),
                  Positioned(
                    top:20,
                    right: -18,
                    child: Image.asset(
                      'assets/rabbit.png', // 토끼 이미지
                      width: 150,
                      height: 150,
                    ),
                  ),
                ],
              ),

              // SizedBox(height: 24),
              // // 1. 아이 이름
              // Text('1. 아이의 이름을 입력해 주세요', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              // TextField(
              //   controller: _nameController,
              //   decoration: InputDecoration(
              //     hintText: '이름 입력',
              //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              //   ),
              // ),



              SizedBox(height: 16),
              // 3. 테마 선택
              Text('1. 테마를 선택해 주세요', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedTheme,
                items: _themes
                    .map((theme) => DropdownMenuItem(value: theme, child: Text(theme)))
                    .toList(),
                hint: Text('테마 선택'),
                onChanged: (val) => setState(() => _selectedTheme = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),

              SizedBox(height: 16),
              // 4. 목소리 선택
              Text('2. 목소리를 선택해 주세요', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedVoice,
                items: _voices
                    .map((voice) => DropdownMenuItem(value: voice, child: Text(voice)))
                    .toList(),
                hint: Text('음성 선택'),
                onChanged: (val) => setState(() => _selectedVoice = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 16),
              // 2. 속도 선택
              Text('3. 속도를 선택해 주세요', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.slow_motion_video, color: primaryColor),
                  Expanded(
                    child: Slider(
                      value: _speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.3),
                      label: _speed.toStringAsFixed(1) + 'x',
                      onChanged: (val) => setState(() => _speed = val),
                    ),
                  ),
                  Icon(Icons.fast_forward, color: primaryColor),
                ],
              ),
              SizedBox(height: 24),
              // 5. 동화 생성 버튼
              ElevatedButton(
                onPressed: _generateStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Text('동화 생성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              SizedBox(height: 24),
              // 6. 생성된 동화 영역
              if (_generatedStory != null) ...[
                Text('생성된 동화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
                  child: Text(_generatedStory!),
                ),

                SizedBox(height: 16),
                // 7. 음성 재생 버튼
                Center(
                  child: IconButton(
                    iconSize: 56,
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      size: 56,
                      color: primaryColor,
                    ),
                    onPressed: _playPauseAudio,
                  ),
                ),

                SizedBox(height: 24),
                // 8. 이미지 선택 버튼
                Text('이미지 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('Color'),
                      selected: _selectedImageMode == 'color',
                      onSelected: (_) => setState(() => _selectedImageMode = 'color'),
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Black/White'),
                      selected: _selectedImageMode == 'bw',
                      onSelected: (_) => setState(() => _selectedImageMode = 'bw'),
                    ),
                  ],
                ),

                SizedBox(height: 24),
                // 9. 동화 이미지 생성 버튼
                Center(
                  child: OutlinedButton(
                    onPressed: _generateImage,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      side: BorderSide(color: primaryColor),
                    ),
                    child: Text('이미지 생성'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
