// lib/stories_screen.dart
import 'package:flutter/material.dart';
import 'main.dart'; // For BaseScaffold

class StoriesScreen extends StatefulWidget {
  @override
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  // 사용자 입력 데이터
  final TextEditingController _nameController = TextEditingController();
  double _speed = 1.0;
  String? _selectedTheme;
  String? _selectedVoice;
  String? _selectedImageMode; // 'color' or 'bw'

  // API 응답 데이터
  String? _generatedStory;
  String? _storyId; // API에서 반환되는 동화 ID
  String? _audioUrl; // TTS 오디오 파일 S3 URL
  List<String> _generatedImages = []; // 생성된 이미지들의 S3 URL 리스트

  // 상태 관리
  bool _isLoading = false;
  bool _isGeneratingStory = false;
  bool _isGeneratingImages = false;
  bool _isPlaying = false;
  String? _errorMessage;

  final List<String> _themes = ['자연', '도전', '가족', '사랑', '우정', '용기'];
  final List<String> _voices = ['아이유', '김태연', '박보검']; // TODO: Google TTS 음성으로 변경

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // 사용자 정보 불러오기
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // TODO: Spring Boot API - 사용자 프로필에서 아이 이름 가져오기
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // final response = await http.get(
      //   Uri.parse('$baseUrl/api/user/profile'),
      //   headers: {'Authorization': 'Bearer $accessToken'},
      // );
      //
      // if (response.statusCode == 200) {
      //   final userData = json.decode(response.body);
      //   setState(() {
      //     _nameController.text = userData['childName'] ?? '';
      //   });
      // }

      // 현재는 더미 데이터
      _nameController.text = '동글이';
    } catch (e) {
      _showError('사용자 정보를 불러오는데 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TODO: Spring Boot API - 동화 생성
  Future<void> _generateStory() async {
    if (_selectedTheme == null || _selectedVoice == null) {
      _showError('테마와 목소리를 모두 선택해주세요.');
      return;
    }

    setState(() {
      _isGeneratingStory = true;
      _errorMessage = null;
      _generatedStory = null;
      _audioUrl = null;
      _generatedImages.clear();
    });

    try {
      // TODO: Spring Boot API - 동화 생성 (OpenAI + Python 연동)
      // final requestData = {
      //   'childName': _nameController.text,
      //   'theme': _selectedTheme,
      //   'voice': _selectedVoice,
      //   'speed': _speed,
      // };
      //
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/stories/generate'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $accessToken',
      //   },
      //   body: json.encode(requestData),
      // );
      //
      // if (response.statusCode == 200) {
      //   final responseData = json.decode(response.body);
      //   setState(() {
      //     _storyId = responseData['storyId'];
      //     _generatedStory = responseData['content']; // Python OpenAI에서 생성
      //     _audioUrl = responseData['audioUrl']; // TTS S3 URL
      //   });
      // } else {
      //   throw Exception('동화 생성에 실패했습니다.');
      // }

      // 현재는 더미 데이터로 시뮬레이션
      await Future.delayed(Duration(seconds: 3));
      setState(() {
        _storyId = 'story_${DateTime.now().millisecondsSinceEpoch}';
        _generatedStory = '''옛날 옛적, ${_nameController.text}이라는 용감한 아이가 살았습니다.
        
${_nameController.text}은(는) $_selectedTheme에 대한 특별한 모험을 떠나게 되었어요.

어느 날, ${_nameController.text}은(는) 마법의 숲에서 신비로운 동물들을 만났습니다. 
그들과 함께 $_selectedTheme에 관한 소중한 교훈을 배우며 성장해 나갔답니다.

마침내 ${_nameController.text}은(는) 모든 어려움을 극복하고 행복하게 살았답니다.''';
        _audioUrl = 'https://s3.bucket.com/audio/${_storyId}.mp3';
      });
    } catch (e) {
      _showError('동화 생성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingStory = false);
    }
  }

  // TODO: TTS 오디오 재생/일시정지
  void _playPauseAudio() {
    if (_audioUrl == null) return;

    setState(() => _isPlaying = !_isPlaying);

    // TODO: 실제 오디오 플레이어 구현
    // if (_isPlaying) {
    //   AudioPlayer.play(_audioUrl!);
    // } else {
    //   AudioPlayer.pause();
    // }

    print('${_isPlaying ? 'Playing' : 'Pausing'} audio: $_audioUrl');
  }

  // TODO: Spring Boot API - 이미지 생성 (1개만)
  Future<void> _generateImage() async {
    if (_generatedStory == null || _selectedImageMode == null) {
      _showError('동화를 먼저 생성하고 이미지 모드를 선택해주세요.');
      return;
    }

    setState(() {
      _isGeneratingImages = true;
      _errorMessage = null;
      _generatedImages.clear();
    });

    try {
      // final requestData = {
      //   'storyId': _storyId,
      //   'storyContent': _generatedStory,
      //   'imageMode': _selectedImageMode, // 'color' or 'bw'
      //   'childName': _nameController.text,
      // };
      //
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/stories/generate-image'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $accessToken',
      //   },
      //   body: json.encode(requestData),
      // );
      //
      // if (response.statusCode == 200) {
      //   final responseData = json.decode(response.body);
      //   setState(() {
      //     _generatedImages = [responseData['imageUrl']]; // 1개 이미지만
      //   });
      // } else {
      //   throw Exception('이미지 생성에 실패했습니다.');
      // }

      // 현재는 더미 데이터로 시뮬레이션 (1개 이미지만)
      await Future.delayed(Duration(seconds: 5));
      setState(() {
        _generatedImages = [
          'https://s3.bucket.com/images/${_storyId}_main.jpg',
        ];
      });
    } catch (e) {
      _showError('이미지 생성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingImages = false);
    }
  }

  // TODO: 동화 저장하기 (제거됨)
  // 저장 기능은 제거하고 공유 기능으로 대체

  // TODO: Spring Boot API - 음성+이미지 합성하여 MP4 생성 및 공유
  Future<void> _shareStoryVideo() async {
    if (_audioUrl == null || _generatedImages.isEmpty) {
      _showError('음성과 이미지가 모두 생성되어야 공유할 수 있습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // final requestData = {
      //   'storyId': _storyId,
      //   'audioUrl': _audioUrl,
      //   'imageUrl': _generatedImages[0],
      //   'storyContent': _generatedStory,
      //   'childName': _nameController.text,
      //   'theme': _selectedTheme,
      // };
      //
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/stories/create-video'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $accessToken',
      //   },
      //   body: json.encode(requestData),
      // );
      //
      // if (response.statusCode == 200) {
      //   final responseData = json.decode(response.body);
      //   final String videoUrl = responseData['videoUrl']; // S3에 저장된 MP4 URL
      //
      //   // Share 페이지로 이동하면서 비디오 URL 전달
      //   Navigator.pushNamed(
      //     context,
      //     '/share',
      //     arguments: {
      //       'videoUrl': videoUrl,
      //       'storyTitle': '${_nameController.text}의 ${_selectedTheme} 동화',
      //       'storyContent': _generatedStory,
      //     },
      //   );
      // } else {
      //   throw Exception('비디오 생성에 실패했습니다.');
      // }

      // 현재는 더미 데이터로 시뮬레이션
      await Future.delayed(Duration(seconds: 3));

      // Share 페이지로 이동
      Navigator.pushNamed(
        context,
        '/share',
        arguments: {
          'videoUrl': 'https://s3.bucket.com/videos/${_storyId}.mp4',
          'storyTitle': '${_nameController.text}의 $_selectedTheme 동화',
          'storyContent': _generatedStory,
          'audioUrl': _audioUrl,
          'imageUrl': _generatedImages[0],
        },
      );

    } catch (e) {
      _showError('비디오 생성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final primaryColor = Color(0xFFF6B756);

    if (_isLoading) {
      return BaseScaffold(
        child: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return BaseScaffold(
      background: Image.asset(
        'assets/bg_image.png',
        fit: BoxFit.cover,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
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
                    'assets/logo.png',
                    height: screenHeight * 0.25,
                  ),
                  Positioned(
                    top: 20,
                    right: -18,
                    child: Image.asset(
                      'assets/rabbit.png',
                      width: screenWidth * 0.375,
                      height: screenWidth * 0.375,
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // 아이 이름 (자동으로 불러온 값) - 가로 배치
              Row(
                children: [
                  Text(
                    '아이 이름: ',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _nameController.text,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // 1. 테마 선택
              Text(
                '1. 테마를 선택해 주세요',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: 8),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // 2. 목소리 선택
              Text(
                '2. 목소리를 선택해 주세요',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: 8),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // 3. 속도 선택
              Text(
                '3. 속도를 선택해 주세요',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
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
              ),

              SizedBox(height: screenHeight * 0.03),

              // 동화 생성 버튼
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  onPressed: _isGeneratingStory ? null : _generateStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isGeneratingStory
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('동화 생성 중...'),
                    ],
                  )
                      : Text(
                    '동화 생성',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 에러 메시지
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],

              // 생성된 동화 영역
              if (_generatedStory != null) ...[
                SizedBox(height: screenHeight * 0.03),
                Text(
                  '생성된 동화',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _generatedStory!,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // 음성 재생 버튼 (가운데 정렬)
                Center(
                  child: IconButton(
                    iconSize: screenWidth * 0.15,
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: primaryColor,
                    ),
                    onPressed: _playPauseAudio,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // 이미지 모드 선택
                Text(
                  '이미지 모드 선택',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('컬러'),
                        selected: _selectedImageMode == 'color',
                        onSelected: (_) => setState(() => _selectedImageMode = 'color'),
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: _selectedImageMode == 'color' ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('흑백 (색칠용)'),
                        selected: _selectedImageMode == 'bw',
                        onSelected: (_) => setState(() => _selectedImageMode = 'bw'),
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: _selectedImageMode == 'bw' ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.02),

                // 이미지 생성 버튼
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.06,
                  child: ElevatedButton(
                    onPressed: _isGeneratingImages ? null : _generateImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isGeneratingImages
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('이미지 생성 중...'),
                      ],
                    )
                        : Text(
                      '이미지 생성',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // 생성된 이미지 표시 (1개만)
              if (_generatedImages.isNotEmpty) ...[
                SizedBox(height: screenHeight * 0.03),
                Text(
                  '생성된 이미지',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Container(
                    width: screenWidth * 0.8,
                    height: screenWidth * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: screenWidth * 0.2,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 16),
                              Text(
                                _selectedImageMode == 'color' ? '컬러 이미지' : '색칠용 이미지',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // TODO: 실제 이미지 로드
                      // child: Image.network(
                      //   _generatedImages[0],
                      //   fit: BoxFit.cover,
                      //   loadingBuilder: (context, child, loadingProgress) {
                      //     if (loadingProgress == null) return child;
                      //     return Center(
                      //       child: CircularProgressIndicator(color: primaryColor),
                      //     );
                      //   },
                      //   errorBuilder: (context, error, stackTrace) {
                      //     return Center(
                      //       child: Column(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //           Icon(Icons.error, color: Colors.red),
                      //           Text('이미지 로드 실패'),
                      //         ],
                      //       ),
                      //     );
                      //   },
                      // ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // 공유 버튼 (이미지가 생성된 후에만 표시)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _shareStoryVideo,
                    icon: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Icon(Icons.share),
                    label: Text(_isLoading ? '비디오 생성 중...' : '동화 공유하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // 이미지 다운로드/색칠하기 버튼
                if (_selectedImageMode == 'bw')
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 색칠하기 화면으로 이동
                        Navigator.pushNamed(
                          context,
                          '/coloring',
                          arguments: {'imageUrl': _generatedImages[0]},
                        );
                      },
                      icon: Icon(Icons.brush),
                      label: Text('색칠하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
              ],

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}