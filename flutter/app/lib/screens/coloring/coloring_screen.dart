// lib/screens/coloring/coloring_screen.dart - 완전히 새로 작성

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';
import '../gallery/GalleryScreen.dart';
import '../service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColoringScreen extends StatefulWidget {
  @override
  _ColoringScreenState createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  // 기본 상태 변수들
  List<ColoringTemplate> _templates = [];
  String? _selectedImageUrl;
  Color _selectedColor = Colors.red;
  double _brushSize = 5.0;
  double _brushOpacity = 1.0;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _showColorPalette = false;
  bool _isBlackAndWhite = false;
  bool _isPanMode = false;

  // 확대/축소 관련
  double _currentScale = 1.0;
  final double _minScale = 0.5;
  final double _maxScale = 3.0;
  final TransformationController _transformationController =
      TransformationController();

  // 그리기 관련
  List<DrawingPoint> _drawingPoints = [];

  // 색상 팔레트
  final List<Color> _colorPalette = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.lightGreen,
    Colors.blue,
    Colors.lightBlue,
    Colors.purple,
    Colors.deepPurple,
    Colors.brown,
    Colors.grey,
    Colors.black,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _loadColoringTemplates();
    _checkForSharedImage();
  }

  // 확대/축소 기능들
  void _zoomIn() {
    final newScale = (_currentScale * 1.3).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() => _currentScale = newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.3).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() => _currentScale = newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  // 템플릿 로드
  Future<void> _loadColoringTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templatesData = await ApiService.getColoringTemplates(
        page: 0,
        size: 20,
      );
      if (templatesData != null && templatesData.isNotEmpty) {
        setState(() {
          _templates =
              templatesData
                  .map((json) => ColoringTemplate.fromJson(json))
                  .toList();
        });
      } else {
        _loadDummyTemplates();
      }
    } catch (e) {
      _loadDummyTemplates();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadDummyTemplates() {
    setState(() {
      _templates = [
        ColoringTemplate(
          id: 'coloring_1',
          title: '토끼와 꽃밭',
          imageUrl: 'https://picsum.photos/400/400?random=1',
          createdAt: '2024-05-30',
          storyTitle: '동글이의 자연 동화',
        ),
        ColoringTemplate(
          id: 'coloring_2',
          title: '마법의 성 모험',
          imageUrl: 'https://picsum.photos/400/400?random=2',
          createdAt: '2024-05-29',
          storyTitle: '동글이의 용기 동화',
        ),
        ColoringTemplate(
          id: 'coloring_3',
          title: '우주 여행',
          imageUrl: 'https://picsum.photos/400/400?random=3',
          createdAt: '2024-05-28',
          storyTitle: '동글이의 도전 동화',
        ),
      ];
    });
  }

  void _checkForSharedImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['imageUrl'] != null) {
        setState(() {
          _selectedImageUrl = args!['imageUrl'] as String;
          _isBlackAndWhite = args['isBlackAndWhite'] ?? false;
        });
      }
    });
  }

  // 이미지 저장
  Future<void> _saveColoredImage() async {
    if (_selectedImageUrl == null || _drawingPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('색칠한 내용이 없습니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // 1. Canvas를 이미지로 변환
      RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        // 2. 현재 선택된 템플릿에서 storyId 가져오기
        String? storyId = _getCurrentTemplateStoryId();

        if (storyId == null) {
          throw Exception('템플릿 정보를 찾을 수 없습니다.');
        }

        // 3. MultipartFile로 Spring Boot API 호출
        final result = await _saveColoringWorkToServer(
          byteData.buffer.asUint8List(),
          storyId,
        );

        if (result?['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎨 색칠 작품이 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          // 갤러리로 이동하면서 성공 메시지 표시
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GalleryScreen(),
              settings: RouteSettings(
                arguments: {
                  'selectedTab': 'coloring', // 색칠 탭으로 이동
                  'showSuccessMessage': true,
                },
              ),
            ),
          );
        } else {
          throw Exception(result?['error'] ?? '저장 실패');
        }
      }
    } catch (e) {
      print('❌ 색칠 완성작 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // 현재 선택된 템플릿의 storyId 가져오기 (안전한 버전)
  String? _getCurrentTemplateStoryId() {
    try {
      print('🔍 템플릿 찾기 시작 - 선택된 URL: $_selectedImageUrl');
      print('🔍 전체 템플릿 개수: ${_templates.length}');

      // 선택된 이미지 URL과 일치하는 템플릿 찾기
      ColoringTemplate? template;

      // 1. 정확히 일치하는 템플릿 찾기
      try {
        template = _templates.firstWhere(
          (t) =>
              t.imageUrl == _selectedImageUrl ||
              t.blackWhiteImageUrl == _selectedImageUrl,
        );
        print('✅ 정확히 일치하는 템플릿 발견: ${template.title}');
      } catch (e) {
        print('⚠️ 정확히 일치하는 템플릿 없음, 대안 방법 시도');

        // 2. URL 일부분 매칭 시도
        template = _templates.cast<ColoringTemplate?>().firstWhere(
          (t) =>
              t != null &&
              ((_selectedImageUrl?.contains(t.id) == true) ||
                  (t.imageUrl.isNotEmpty &&
                      _selectedImageUrl?.contains('image-') == true) ||
                  (t.storyId != null &&
                      _selectedImageUrl?.contains(t.storyId!) == true)),
          orElse: () => null,
        );

        if (template != null) {
          print('✅ 부분 매칭으로 템플릿 발견: ${template.title}');
        }
      }

      // 3. 템플릿을 찾지 못한 경우, 첫 번째 템플릿 사용
      if (template == null && _templates.isNotEmpty) {
        template = _templates.first;
        print('⚠️ 매칭 실패, 첫 번째 템플릿 사용: ${template.title}');
      }

      if (template != null) {
        final storyId = template.storyId ?? template.id;
        print('✅ 최종 StoryId: $storyId');
        return storyId;
      }

      print('❌ 사용할 수 있는 템플릿이 없음');
      return null;
    } catch (e) {
      print('❌ 템플릿 찾기 실패: $e');

      // 최후의 수단: 첫 번째 템플릿 사용
      if (_templates.isNotEmpty) {
        final fallbackTemplate = _templates.first;
        print('🔄 폴백: 첫 번째 템플릿 사용 - ${fallbackTemplate.title}');
        return fallbackTemplate.storyId ?? fallbackTemplate.id;
      }

      return null;
    }
  }

  // 서버에 색칠 완성작 저장
  Future<Map<String, dynamic>?> _saveColoringWorkToServer(
    Uint8List imageData,
    String storyId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // MultipartRequest 생성
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/coloring/save-coloring-work'),
      );

      // 헤더 설정
      request.headers['Authorization'] = 'Bearer $accessToken';

      // 파라미터 추가
      request.fields['storyId'] = storyId;

      // 이미지 파일 추가
      request.files.add(
        http.MultipartFile.fromBytes(
          'coloredImage',
          imageData,
          filename:
              'coloring_work_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );

      print('🎨 색칠 완성작 저장 요청 - StoryId: $storyId');

      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🎨 색칠 완성작 저장 응답: ${response.statusCode}');
      print('🎨 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 색칠 완성작 저장 실패: $e');
      throw e;
    }
  }

  void _clearCanvas() => setState(() => _drawingPoints.clear());

  void _undoLastStroke() {
    if (_drawingPoints.isNotEmpty) {
      setState(() {
        while (_drawingPoints.isNotEmpty && _drawingPoints.last.color != null) {
          _drawingPoints.removeLast();
        }
        if (_drawingPoints.isNotEmpty) _drawingPoints.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black54,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '색칠공부',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.06),
                ],
              ),
            ),

            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD3A8)),
                ),
              )
            else if (_selectedImageUrl != null)
              Expanded(child: _buildColoringCanvas(screenWidth, screenHeight))
            else
              Expanded(child: _buildTemplateGrid(screenWidth, screenHeight)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGrid(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Color(0xFFFFD3A8).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Color(0xFFFFD3A8),
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    '저장된 동화 이미지를 선택해서 색칠해보세요!',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.04,
              mainAxisSpacing: screenWidth * 0.04,
              childAspectRatio: 0.8,
            ),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImageUrl = template.imageUrl;
                    _drawingPoints.clear();
                    _isBlackAndWhite = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            template.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFD3A8),
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                template.storyTitle,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColoringCanvas(double screenWidth, double screenHeight) {
    return Column(
      children: [
        // 상단 컨트롤
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: 8,
          ),
          child: Row(
            children: [
              // 이동 모드 버튼
              GestureDetector(
                onTap: () => setState(() => _isPanMode = !_isPanMode),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isPanMode ? Color(0xFFFFD3A8) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isPanMode ? '📍 이동' : '🖌️ 색칠',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: _isPanMode ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // 색상 버튼
              GestureDetector(
                onTap:
                    () =>
                        setState(() => _showColorPalette = !_showColorPalette),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        _showColorPalette
                            ? Color(0xFFFFD3A8)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '색상',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color:
                              _showColorPalette
                                  ? Colors.white
                                  : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 색상 팔레트
        if (_showColorPalette)
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _colorPalette.length,
              itemBuilder: (context, index) {
                final color = _colorPalette[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _selectedColor == color
                                ? Colors.black
                                : Colors.grey,
                        width: _selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // 브러시 컨트롤
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              // 브러시 크기
              Row(
                children: [
                  Text(
                    '크기: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Slider(
                      value: _brushSize,
                      min: 2.0,
                      max: 25.0,
                      activeColor: Color(0xFFFFD3A8),
                      onChanged: (value) => setState(() => _brushSize = value),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(_brushOpacity),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                  ),
                ],
              ),
              // 투명도
              Row(
                children: [
                  Text(
                    '투명도: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Slider(
                      value: _brushOpacity,
                      min: 0.1,
                      max: 1.0,
                      activeColor: Color(0xFFFFD3A8),
                      onChanged:
                          (value) => setState(() => _brushOpacity = value),
                    ),
                  ),
                  Text(
                    '${(_brushOpacity * 100).round()}%',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 메인 캔버스
        Expanded(
          child: Container(
            margin: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
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
              child: Stack(
                children: [
                  // 캔버스
                  RepaintBoundary(
                    key: _canvasKey,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      panEnabled: false,
                      scaleEnabled: false,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Stack(
                          children: [
                            // 배경 이미지
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(_selectedImageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // 터치 레이어
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart:
                                    _isPanMode
                                        ? null
                                        : (details) {
                                          setState(() {
                                            _drawingPoints.add(
                                              DrawingPoint(
                                                offset: details.localPosition,
                                                color: _selectedColor
                                                    .withOpacity(_brushOpacity),
                                                strokeWidth: _brushSize,
                                              ),
                                            );
                                          });
                                        },
                                onPanUpdate:
                                    _isPanMode
                                        ? (details) {
                                          final transform =
                                              _transformationController.value;
                                          final newTransform = Matrix4.copy(
                                            transform,
                                          );
                                          newTransform.translate(
                                            details.delta.dx,
                                            details.delta.dy,
                                          );
                                          _transformationController.value =
                                              newTransform;
                                        }
                                        : (details) {
                                          setState(() {
                                            _drawingPoints.add(
                                              DrawingPoint(
                                                offset: details.localPosition,
                                                color: _selectedColor
                                                    .withOpacity(_brushOpacity),
                                                strokeWidth: _brushSize,
                                              ),
                                            );
                                          });
                                        },
                                onPanEnd:
                                    _isPanMode
                                        ? null
                                        : (details) {
                                          setState(
                                            () => _drawingPoints.add(
                                              DrawingPoint(),
                                            ),
                                          );
                                        },
                                child: CustomPaint(
                                  painter: ColoringPainter(_drawingPoints),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 상단 버튼들 (확대/축소만)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 축소
                        _buildZoomButton(
                          Icons.remove,
                          _currentScale > _minScale,
                          _zoomOut,
                        ),
                        SizedBox(width: 12),
                        // 홈/배율
                        GestureDetector(
                          onTap: _resetZoom,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '${(_currentScale * 100).round()}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // 확대
                        _buildZoomButton(
                          Icons.add,
                          _currentScale < _maxScale,
                          _zoomIn,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 하단 버튼들
        Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _drawingPoints.isNotEmpty ? _undoLastStroke : null,
                  child: Text('실행취소'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _drawingPoints.isNotEmpty ? _clearCanvas : null,
                  child: Text('전체지우기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _saveColoredImage,
                  child:
                      _isProcessing
                          ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                          : Text('저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD3A8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, bool enabled, VoidCallback? onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: enabled ? Color(0xFFFFD3A8) : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

// 드로잉 포인트 클래스
class DrawingPoint {
  final Offset? offset;
  final Color? color;
  final double? strokeWidth;

  DrawingPoint({this.offset, this.color, this.strokeWidth});
}

// 페인터 클래스
class ColoringPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  ColoringPainter(this.drawingPoints);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    for (int i = 0; i < drawingPoints.length; i++) {
      final point = drawingPoints[i];

      if (point.offset != null && point.color != null) {
        paint.color = point.color!;
        paint.strokeWidth = point.strokeWidth ?? 5.0;

        if (i > 0 &&
            drawingPoints[i - 1].offset != null &&
            drawingPoints[i - 1].color != null) {
          canvas.drawLine(drawingPoints[i - 1].offset!, point.offset!, paint);
        } else {
          canvas.drawCircle(point.offset!, paint.strokeWidth / 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ColoringTemplate 모델 수정
class ColoringTemplate {
  final String id;
  final String title;
  final String imageUrl;
  final String? blackWhiteImageUrl; // 흑백 이미지 URL 추가
  final String createdAt;
  final String storyTitle;
  final String? storyId; // StoryId 추가

  ColoringTemplate({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.blackWhiteImageUrl,
    required this.createdAt,
    required this.storyTitle,
    this.storyId,
  });

  factory ColoringTemplate.fromJson(Map<String, dynamic> json) {
    return ColoringTemplate(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '제목 없음',
      imageUrl: json['originalImageUrl'] ?? json['imageUrl'] ?? '', // 컬러 이미지
      blackWhiteImageUrl: json['blackWhiteImageUrl'], // 흑백 이미지
      createdAt: json['createdAt'] ?? '',
      storyTitle: json['title'] ?? '동화 제목 없음',
      storyId: json['storyId']?.toString(), // 이게 핵심!
    );
  }
}
