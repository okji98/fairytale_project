// lib/stories_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../main.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';

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
  int? _storyId;
  String? _audioUrl; // 로컬 파일 경로 또는 HTTP URL
  String? _colorImageUrl;

  // 상태 관리
  bool _isLoading = false;
  bool _isGeneratingStory = false;
  bool _isGeneratingImage = false;
  bool _isGeneratingBlackWhite = false;
  bool _isPlaying = false;
  String? _errorMessage;

  // 🎯 AudioPlayer 인스턴스
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final List<String> _themes = ['자연', '도전', '가족', '사랑', '우정', '용기'];
  final List<String> _voices = [
    "alloy",
    "echo",
    "fable",
    "onyx",
    "nova",
    "shimmer",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // AudioPlayer 초기화
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // AudioPlayer 이벤트 리스너 설정
  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _playerState = state;
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
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
// 사용자 프로필 로드
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // AuthService를 통해 아이 정보 가져오기
      final childInfo = await AuthService.checkChildInfo();

      if (childInfo != null && childInfo['hasChild'] == true) {
        final childData = childInfo['childData'];
        _nameController.text = childData['name'] ?? '우리 아이';
      } else {
        _nameController.text = '우리 아이'; // 기본값
      }
    } catch (e) {
      print('아이 정보 로드 오류: $e');
      _nameController.text = '우리 아이'; // 오류 시 기본값
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

      // 오디오 초기화
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
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

  // 🎯 로컬 파일 처리가 가능한 음성 생성
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

        print('🔍 원본 음성 경로: $voiceUrl');

        if (voiceUrl != null) {
          // 🎯 로컬 파일 경로와 HTTP URL 모두 처리
          await _processAudioUrl(voiceUrl);
        }
      }
    } catch (e) {
      print('❌ 음성 생성 에러: $e');
    }
  }

  // 🎯 오디오 URL 처리 (로컬 파일 다운로드 + HTTP URL 지원)
  Future<void> _processAudioUrl(String audioPath) async {
    try {
      // HTTP URL인 경우 바로 사용
      if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
        print('✅ HTTP URL 음성 파일: $audioPath');
        setState(() {
          _audioUrl = audioPath;
        });

        try {
          await _audioPlayer.setSourceUrl(_audioUrl!);
          print('✅ HTTP 오디오 미리 로드 완료');
        } catch (e) {
          print('⚠️ HTTP 오디오 미리 로드 실패: $e');
        }
        return;
      }

      // 🎯 로컬 파일 경로인 경우 서버에서 다운로드
      if (audioPath.startsWith('/') ||
          audioPath.contains('/tmp/') ||
          audioPath.contains('/var/')) {
        print('🔍 로컬 파일 경로 감지, 다운로드 시도: $audioPath');
        await _downloadAndSaveAudioFile(audioPath);
        return;
      }

      // 기타 경우
      print('⚠️ 알 수 없는 오디오 경로 형식: $audioPath');
      _showError('지원하지 않는 음성 파일 형식입니다.');
    } catch (e) {
      print('❌ 오디오 URL 처리 에러: $e');
      _showError('음성 파일 처리 중 오류가 발생했습니다.');
    }
  }

  // 🎯 서버에서 로컬 오디오 파일 다운로드
  Future<void> _downloadAndSaveAudioFile(String serverFilePath) async {
    try {
      print('🔍 서버 오디오 파일 다운로드 시작: $serverFilePath');

      // 1. 서버에 파일 다운로드 요청
      final headers = await _getAuthHeaders();
      final requestData = {'filePath': serverFilePath};

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/download/audio'),
        headers: headers,
        body: json.encode(requestData),
      );

      print('🔍 오디오 다운로드 API 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 2. 바이너리 데이터로 파일 받기
        final audioBytes = response.bodyBytes;
        print('🔍 받은 오디오 데이터 크기: ${audioBytes.length} bytes');

        if (audioBytes.isEmpty) {
          throw Exception('서버에서 빈 오디오 파일을 받았습니다.');
        }

        // 3. 앱의 임시 디렉토리에 저장
        final appDir = await getTemporaryDirectory();
        final fileName =
            'story_audio_${_storyId}_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final localFile = File('${appDir.path}/$fileName');

        await localFile.writeAsBytes(audioBytes);
        print('✅ 로컬 파일 저장 완료: ${localFile.path}');

        // 4. 로컬 파일 경로로 AudioPlayer 설정
        setState(() {
          _audioUrl = localFile.path;
        });

        // 5. 오디오 미리 로드
        try {
          await _audioPlayer.setSourceDeviceFile(_audioUrl!);
          print('✅ 로컬 오디오 파일 미리 로드 완료');
        } catch (e) {
          print('⚠️ 로컬 오디오 미리 로드 실패: $e');
        }
      } else {
        throw Exception('오디오 다운로드 API 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 오디오 파일 다운로드 실패: $e');

      // 🎯 폴백: 테스트 오디오 사용
      print('🔄 테스트 오디오로 대체');
      setState(() {
        _audioUrl = 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
      });

      _showError('음성 파일 다운로드에 실패했습니다. 테스트 오디오를 사용합니다.');
    }
  }

  // 🎯 로컬/HTTP 파일 모두 지원하는 음성 재생
  Future<void> _playPauseAudio() async {
    if (_audioUrl == null) {
      _showError('음성이 생성되지 않았습니다.');
      return;
    }

    try {
      if (_isPlaying) {
        // 일시정지
        print('🎵 음성 일시정지');
        await _audioPlayer.pause();
      } else {
        // 재생
        print('🎵 음성 재생 시작: $_audioUrl');

        if (_position == Duration.zero) {
          // 처음 재생하는 경우
          if (_audioUrl!.startsWith('http')) {
            // HTTP URL
            await _audioPlayer.play(UrlSource(_audioUrl!));
          } else {
            // 로컬 파일
            await _audioPlayer.play(DeviceFileSource(_audioUrl!));
          }
        } else {
          // 일시정지된 상태에서 재개
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('❌ 음성 재생 에러: $e');

      // 🎯 에러 발생 시 재시도
      if (e.toString().contains('setSource')) {
        print('🔄 소스 설정 에러, 재시도...');
        try {
          await _audioPlayer.stop();
          await Future.delayed(Duration(milliseconds: 500));

          if (_audioUrl!.startsWith('http')) {
            await _audioPlayer.setSourceUrl(_audioUrl!);
          } else {
            await _audioPlayer.setSourceDeviceFile(_audioUrl!);
          }

          await _audioPlayer.resume();
          print('✅ 재시도 성공');
        } catch (retryError) {
          print('❌ 재시도도 실패: $retryError');
          _showError('음성 재생에 실패했습니다.');
        }
      } else {
        _showError('음성 재생 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  // 음성 정지
  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    } catch (e) {
      print('❌ 음성 정지 에러: $e');
    }
  }

  // 재생 시간을 문자열로 변환
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // 컬러 이미지 생성
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

        String? imageUrl;

        if (responseData.containsKey('image')) {
          imageUrl = responseData['image'];
        } else if (responseData.containsKey('imageUrl')) {
          imageUrl = responseData['imageUrl'];
        } else if (responseData.containsKey('image_url')) {
          imageUrl = responseData['image_url'];
        } else if (responseData.containsKey('colorImageUrl')) {
          imageUrl = responseData['colorImageUrl'];
        }

        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
          setState(() {
            _colorImageUrl = imageUrl;
          });
          print('✅ 컬러 이미지 생성 완료: $imageUrl');
        } else {
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

  // 흑백 이미지 변환 및 색칠하기 화면 이동
  Future<void> _getBlackWhiteImageAndNavigate() async {
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
      final requestData = {'text': _colorImageUrl!};

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/fairytale/convert/bwimage'),
        headers: await _getAuthHeaders(),
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        String? blackWhiteImageUrl;

        if (responseData.containsKey('image_url')) {
          blackWhiteImageUrl = responseData['image_url'];
        } else if (responseData.containsKey('path')) {
          blackWhiteImageUrl = responseData['path'];
        }

        if (blackWhiteImageUrl != null && blackWhiteImageUrl.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/coloring',
            arguments: {
              'imageUrl':
                  blackWhiteImageUrl.startsWith('http')
                      ? blackWhiteImageUrl
                      : _colorImageUrl!,
              'isBlackAndWhite': false,
            },
          );
          return;
        }
      }

      throw Exception('흑백 변환 실패');
    } catch (e) {
      Navigator.pushNamed(
        context,
        '/coloring',
        arguments: {'imageUrl': _colorImageUrl!, 'isBlackAndWhite': false},
      );
    } finally {
      setState(() => _isGeneratingBlackWhite = false);
    }
  }

  // 공유 기능
  Future<void> _shareStoryVideo() async {
    if (_audioUrl == null || _colorImageUrl == null) {
      _showError('음성과 이미지가 모두 생성되어야 공유할 수 있습니다.');
      return;
    }

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

                // 🎯 향상된 음성 재생 컨트롤 (로컬/HTTP 파일 지원)
                if (_audioUrl != null) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 🎯 파일 타입 표시
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _audioUrl!.startsWith('http')
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _audioUrl!.startsWith('http')
                                ? '🌐 온라인 음성'
                                : '📱 로컬 음성',
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color:
                                  _audioUrl!.startsWith('http')
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        // 재생/일시정지 버튼들
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 재생/일시정지 버튼
                            IconButton(
                              iconSize: screenWidth * 0.15,
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: primaryColor,
                              ),
                              onPressed: _playPauseAudio,
                            ),
                            SizedBox(width: 20),
                            // 정지 버튼
                            IconButton(
                              iconSize: screenWidth * 0.08,
                              icon: Icon(Icons.stop, color: Colors.grey[600]),
                              onPressed:
                                  _isPlaying || _position > Duration.zero
                                      ? _stopAudio
                                      : null,
                            ),
                          ],
                        ),

                        // 재생 진행 바
                        if (_duration > Duration.zero) ...[
                          SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _position.inMilliseconds.toDouble(),
                              min: 0.0,
                              max: _duration.inMilliseconds.toDouble(),
                              activeColor: primaryColor,
                              inactiveColor: primaryColor.withOpacity(0.3),
                              onChanged: (value) async {
                                final newPosition = Duration(
                                  milliseconds: value.toInt(),
                                );
                                await _audioPlayer.seek(newPosition);
                              },
                            ),
                          ),

                          // 시간 표시
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],

                        // 🎯 디버깅 정보 (개발용)
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Debug 정보:',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '파일 경로: ${_audioUrl!.length > 50 ? _audioUrl!.substring(0, 50) + '...' : _audioUrl!}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.025,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '상태: ${_playerState.toString()}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.025,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // 음성이 아직 생성되지 않은 경우
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '음성 생성 중...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: screenHeight * 0.03),

                // 이미지 생성 섹션
                if (_colorImageUrl == null) ...[
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
                  // 컬러 이미지가 생성된 후 표시되는 영역
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

                  // 버튼들
                  Row(
                    children: [
                      // 흑백(색칠용) 버튼
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
                            _isGeneratingBlackWhite ? '변환중...' : '흑백(색칠용)',
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
                          onPressed: _shareStoryVideo,
                          icon: Icon(Icons.share),
                          label: Text('동화 공유하기'),
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
