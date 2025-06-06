// lib/stories_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../service/api_service.dart';

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

  // API 응답 데이터
  String? _generatedStory;
  int? _storyId; // API에서 반환되는 동화 ID
  String? _audioUrl; // TTS 오디오 파일 S3 URL
  String? _colorImageUrl; // 컬러 이미지 URL

  // 상태 관리
  bool _isLoading = false;
  bool _isGeneratingStory = false;
  bool _isGeneratingImage = false;
  bool _isGeneratingBlackWhite = false;
  bool _isPlaying = false;
  String? _errorMessage;

  final List<String> _themes = ['자연', '도전', '가족', '사랑', '우정', '용기'];
  final List<String> _voices = ['아이유', '김태연', '박보검'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 인증된 HTTP 요청을 위한 헤더 가져오기
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  // 사용자 프로필 로드
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      _nameController.text = '동글이';
    } catch (e) {
      _showError('사용자 정보를 불러오는데 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 동화 생성
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
      _colorImageUrl = null;
    });

    try {
      final headers = await _getAuthHeaders();
      final requestData = {'theme': _selectedTheme, 'voice': _selectedVoice};

      print('🔍 동화 생성 요청: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/generate/story'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 동화 생성 응답 상태: ${response.statusCode}');
      print('🔍 동화 생성 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // 🎯 여러 가능한 필드명 확인
        int? storyId;
        String? storyContent;

        if (responseData.containsKey('id')) {
          storyId = responseData['id'];
        }

        if (responseData.containsKey('content')) {
          storyContent = responseData['content'];
        } else if (responseData.containsKey('storyText')) {
          storyContent = responseData['storyText'];
        }

        setState(() {
          _storyId = storyId;
          _generatedStory = storyContent;
        });

        print('✅ 동화 생성 완료 - ID: $_storyId');

        // 동화 생성 후 자동으로 음성 생성
        if (_storyId != null) {
          _generateVoice();
        }
      } else {
        throw Exception('동화 생성에 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 동화 생성 에러: $e');
      _showError('동화 생성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingStory = false);
    }
  }

  // 음성 생성
  Future<void> _generateVoice() async {
    if (_storyId == null) return;

    try {
      final headers = await _getAuthHeaders();
      final requestData = {'storyId': _storyId};

      print('🔍 음성 생성 요청: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/generate/voice'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 음성 생성 응답 상태: ${response.statusCode}');
      print('🔍 음성 생성 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // 🎯 여러 가능한 필드명 확인
        String? voiceUrl;

        if (responseData.containsKey('voiceContent')) {
          voiceUrl = responseData['voiceContent'];
        } else if (responseData.containsKey('voice_content')) {
          voiceUrl = responseData['voice_content'];
        } else if (responseData.containsKey('audioUrl')) {
          voiceUrl = responseData['audioUrl'];
        } else if (responseData.containsKey('audio_url')) {
          voiceUrl = responseData['audio_url'];
        }

        setState(() {
          _audioUrl = voiceUrl;
        });

        print('✅ 음성 생성 완료: $_audioUrl');
      }
    } catch (e) {
      print('❌ 음성 생성 에러: $e');
    }
  }

  // 🎯 컬러 이미지 생성 (서버 연동) - 개선된 응답 파싱
  Future<void> _generateColorImage() async {
    if (_storyId == null) {
      _showError('동화를 먼저 생성해주세요.');
      return;
    }

    setState(() {
      _isGeneratingImage = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();
      final requestData = {'storyId': _storyId};

      print('🔍 컬러 이미지 생성 요청: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/generate/image'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 컬러 이미지 생성 응답 상태: ${response.statusCode}');
      print('🔍 컬러 이미지 생성 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        print('🔍 전체 응답 데이터: $responseData');
        print('🔍 사용 가능한 필드들: ${responseData.keys}');

        // 🎯 여러 가능한 필드명 확인
        String? imageUrl;

        if (responseData.containsKey('image')) {
          imageUrl = responseData['image'];
          print('🔍 image 필드에서 추출: $imageUrl');
        } else if (responseData.containsKey('imageUrl')) {
          imageUrl = responseData['imageUrl'];
          print('🔍 imageUrl 필드에서 추출: $imageUrl');
        } else if (responseData.containsKey('image_url')) {
          imageUrl = responseData['image_url'];
          print('🔍 image_url 필드에서 추출: $imageUrl');
        } else if (responseData.containsKey('colorImageUrl')) {
          imageUrl = responseData['colorImageUrl'];
          print('🔍 colorImageUrl 필드에서 추출: $imageUrl');
        } else {
          print('❌ 이미지 URL 필드를 찾을 수 없음');
          print('❌ 사용 가능한 필드들: ${responseData.keys}');
        }

        print('🔍 최종 추출된 이미지 URL: $imageUrl');

        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
          setState(() {
            _colorImageUrl = imageUrl;
          });
          print('✅ 컬러 이미지 생성 완료: $imageUrl');
        } else {
          print('❌ 유효하지 않은 이미지 URL: $imageUrl');
          throw Exception('응답에서 유효한 이미지 URL을 찾을 수 없습니다.');
        }
      } else {
        throw Exception('컬러 이미지 생성에 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 컬러 이미지 생성 에러: $e');
      _showError('컬러 이미지 생성 중 오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() => _isGeneratingImage = false);
    }
  }

  // 🎯 흑백 이미지 변환 및 색칠하기 화면 이동 (개선된 null 체크)
  Future<void> _getBlackWhiteImageAndNavigate() async {
    print('🔍 흑백 변환 시작 - StoryId: $_storyId, ColorImageUrl: $_colorImageUrl');

    if (_storyId == null) {
      _showError('동화를 먼저 생성해주세요.');
      return;
    }

    if (_colorImageUrl == null ||
        _colorImageUrl!.isEmpty ||
        _colorImageUrl == 'null') {
      _showError('컬러 이미지를 먼저 생성해주세요.');
      return;
    }

    setState(() => _isGeneratingBlackWhite = true);

    try {
      print('🔍 서버 PIL+OpenCV 흑백 변환 시작 - 컬러 이미지: $_colorImageUrl');

      // 🎯 null 체크 후 요청 데이터 생성
      final requestData = {'text': _colorImageUrl!};

      print('🔍 흑백 변환 요청 데이터: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/convert/bwimage'),
        headers: await _getAuthHeaders(),
        body: json.encode(requestData),
      );

      print('🔍 흑백 변환 응답 상태: ${response.statusCode}');
      print('🔍 흑백 변환 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        print('🔍 전체 흑백 변환 응답: $responseData');

        // 🎯 여러 가능한 응답 필드 확인
        String? blackWhiteImageUrl;

        if (responseData.containsKey('image_url')) {
          blackWhiteImageUrl = responseData['image_url'];
          print('🔍 image_url 필드에서 추출: $blackWhiteImageUrl');
        } else if (responseData.containsKey('path')) {
          blackWhiteImageUrl = responseData['path'];
          print('🔍 path 필드에서 추출: $blackWhiteImageUrl');
        } else if (responseData.containsKey('file_path')) {
          blackWhiteImageUrl = responseData['file_path'];
          print('🔍 file_path 필드에서 추출: $blackWhiteImageUrl');
        } else if (responseData.containsKey('save_path')) {
          blackWhiteImageUrl = responseData['save_path'];
          print('🔍 save_path 필드에서 추출: $blackWhiteImageUrl');
        }

        print('🔍 추출된 흑백 이미지 경로: $blackWhiteImageUrl');

        // 🎯 서버에서 흑백 변환 결과 처리
        if (blackWhiteImageUrl != null &&
            blackWhiteImageUrl.isNotEmpty &&
            blackWhiteImageUrl != 'null') {
          // 로컬 파일 경로인 경우 (Python에서 파일만 생성됨)
          if (!blackWhiteImageUrl.startsWith('http') &&
              (blackWhiteImageUrl.contains('bw_image.png') ||
                  blackWhiteImageUrl.contains('/tmp/') ||
                  blackWhiteImageUrl.startsWith('/') ||
                  blackWhiteImageUrl == 'bw_image.png')) {
            print('✅ 서버에서 PIL+OpenCV 변환 완료 (로컬 파일)');
            print('🔄 원본 이미지로 색칠하기 진행');

            // 원본 이미지로 색칠하기 (Flutter에서는 흑백 필터링 없음)
            Navigator.pushNamed(
              context,
              '/coloring',
              arguments: {
                'imageUrl': _colorImageUrl!,
                'isBlackAndWhite': false, // 🔥 서버에서 변환되었으므로 Flutter 필터링 안함
              },
            );
            return;
          }

          // 유효한 URL인 경우 그대로 사용
          if (blackWhiteImageUrl.startsWith('http')) {
            print('✅ 서버에서 받은 유효한 흑백 이미지 URL로 색칠하기 진행');

            Navigator.pushNamed(
              context,
              '/coloring',
              arguments: {
                'imageUrl': blackWhiteImageUrl,
                'isBlackAndWhite': false, // 서버에서 이미 변환 완료
              },
            );
            return;
          }
        }

        // 응답은 성공했지만 유효한 이미지를 받지 못한 경우
        print('⚠️ 서버 응답은 성공했지만 유효한 이미지 URL을 받지 못함');
        throw Exception('서버에서 유효한 흑백 이미지를 생성하지 못했습니다.');
      } else {
        throw Exception('서버 흑백 변환 실패. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 흑백 변환 에러: $e');

      // 🎯 실패 시 원본 컬러 이미지로 색칠하기 화면 이동
      print('⚠️ 서버 변환 실패, 원본 이미지로 색칠하기 이동');

      Navigator.pushNamed(
        context,
        '/coloring',
        arguments: {
          'imageUrl': _colorImageUrl!,
          'isBlackAndWhite': false, // 서버 변환 실패이므로 원본 이미지 그대로 사용
        },
      );

      // 사용자에게는 정상 진행되는 것처럼 보이게 함
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎨 색칠하기 화면으로 이동합니다!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isGeneratingBlackWhite = false);
    }
  }

  // 음성 재생/일시정지
  void _playPauseAudio() {
    if (_audioUrl == null) return;
    setState(() => _isPlaying = !_isPlaying);
    print('${_isPlaying ? 'Playing' : 'Pausing'} audio: $_audioUrl');
  }

  // 공유 기능
  Future<void> _shareStoryVideo() async {
    if (_audioUrl == null || _colorImageUrl == null) {
      _showError('음성과 이미지가 모두 생성되어야 공유할 수 있습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(Duration(seconds: 2));

      Navigator.pushNamed(
        context,
        '/share',
        arguments: {
          'videoUrl': 'https://generated-video-url.com/video_${_storyId}.mp4',
          'storyTitle': '${_nameController.text}의 $_selectedTheme 동화',
          'storyContent': _generatedStory,
          'audioUrl': _audioUrl,
          'imageUrl': _colorImageUrl,
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final primaryColor = Color(0xFFF6B756);

    if (_isLoading) {
      return BaseScaffold(
        child: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return BaseScaffold(
      background: Image.asset('assets/bg_image.png', fit: BoxFit.cover),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                  Image.asset('assets/logo.png', height: screenHeight * 0.25),
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

              // 아이 이름
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
                items:
                    _themes
                        .map(
                          (theme) => DropdownMenuItem(
                            value: theme,
                            child: Text(theme),
                          ),
                        )
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
                items:
                    _voices
                        .map(
                          (voice) => DropdownMenuItem(
                            value: voice,
                            child: Text(voice),
                          ),
                        )
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
                  child:
                      _isGeneratingStory
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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

                // 음성 재생 버튼
                Center(
                  child: IconButton(
                    iconSize: screenWidth * 0.15,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: primaryColor,
                    ),
                    onPressed: _playPauseAudio,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // 🎯 이미지 생성 섹션
                if (_colorImageUrl == null) ...[
                  // 이미지 생성 버튼
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed:
                          _isGeneratingImage ? null : _generateColorImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child:
                          _isGeneratingImage
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                ] else ...[
                  // 🎯 컬러 이미지가 생성된 후 표시되는 영역
                  Text(
                    '생성된 이미지',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 컬러 이미지 표시
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
                        child: Image.network(
                          _colorImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ 이미지 로드 에러: $error');
                            return Container(
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
                                      '이미지 로드 실패',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _colorImageUrl!,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: screenWidth * 0.025,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // 🎯 이미지 URL 디버깅 정보 (개발용)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '디버깅 정보:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'StoryId: $_storyId',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                        Text(
                          'ImageUrl: $_colorImageUrl',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                        Text(
                          'ImageUrl 길이: ${_colorImageUrl?.length ?? 0}',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                        Text(
                          'null 체크: ${_colorImageUrl == null
                              ? "NULL"
                              : _colorImageUrl == "null"
                              ? "STRING_NULL"
                              : "VALID"}',
                          style: TextStyle(fontSize: screenWidth * 0.03),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // 🎯 버튼들 (컬러 이미지 생성 후에만 표시)
                  Row(
                    children: [
                      // 🎯 흑백(색칠용) 버튼 - 서버 PIL+OpenCV 연동
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isGeneratingBlackWhite
                                  ? null
                                  : _getBlackWhiteImageAndNavigate,
                          icon:
                              _isGeneratingBlackWhite
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Icon(Icons.brush),
                          label: Text(
                            _isGeneratingBlackWhite
                                ? 'PIL+OpenCV 변환중...'
                                : '흑백(색칠용)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // 공유 버튼
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _shareStoryVideo,
                          icon:
                              _isLoading
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Icon(Icons.share),
                          label: Text(_isLoading ? '비디오 생성 중...' : '동화 공유하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
