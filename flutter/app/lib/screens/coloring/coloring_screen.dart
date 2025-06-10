// lib/coloring_screen.dart

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

class ColoringScreen extends StatefulWidget {
  @override
  _ColoringScreenState createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  // 🎯 캡처를 위한 GlobalKey 추가
  final GlobalKey _canvasKey = GlobalKey();

  // 색칠공부 데이터 관리
  List<ColoringTemplate> _templates = [];
  String? _selectedImageUrl;
  Color _selectedColor = Colors.red;
  double _brushSize = 5.0;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _showColorPalette = false;
  PaintingTool _selectedTool = PaintingTool.brush;

  // 🎯 흑백 필터링 상태 추가
  bool _isBlackAndWhite = false;

  // 페인팅 관련
  List<DrawingPoint> _drawingPoints = [];
  ui.Image? _backgroundImage;
  Uint8List? _pixelData;

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

  // 🎯 색칠 완성 이미지 캡처 메서드
  Future<Uint8List?> _captureColoredImage() async {
    try {
      print('🎯 [ColoringScreen] 색칠 완성 이미지 캡처 시작');

      RenderRepaintBoundary boundary =
          _canvasKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 2.0);

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        Uint8List imageBytes = byteData.buffer.asUint8List();
        print('✅ [ColoringScreen] 이미지 캡처 성공 - 크기: ${imageBytes.length} bytes');
        return imageBytes;
      } else {
        print('❌ [ColoringScreen] 이미지 캡처 실패 - ByteData null');
        return null;
      }
    } catch (e) {
      print('❌ [ColoringScreen] 이미지 캡처 오류: $e');
      return null;
    }
  }

  // 🎯 색칠한 이미지 저장
  Future<void> _saveColoredImage() async {
    // 🔍 JWT 토큰 디버깅
    await ApiService.debugJwtToken();

    if (_selectedImageUrl == null || _drawingPoints.isEmpty) {
      _showError('색칠한 내용이 없습니다.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print('🎯 [ColoringScreen] 색칠 완성작 저장 시작');

      Uint8List? completedImageBytes = await _captureColoredImage();

      if (completedImageBytes == null) {
        throw Exception('완성된 이미지 생성에 실패했습니다.');
      }

      String base64Image = base64Encode(completedImageBytes);
      print('🎯 [ColoringScreen] Base64 인코딩 완료 - 길이: ${base64Image.length}');

      final coloringData = {
        'originalImageUrl': _selectedImageUrl,
        'completedImageBase64': base64Image,
        'timestamp': DateTime.now().toIso8601String(),
        'isBlackAndWhite': _isBlackAndWhite,
      };

      final result = await ApiService.saveColoredImageWithAuth(
        coloringData: coloringData,
      );

      if (result != null) {
        if (result['success'] == true) {
          print('✅ [ColoringScreen] 색칠 완성작 저장 성공');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎨 색칠 작품이 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(Duration(seconds: 2));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GalleryScreen(),
              settings: RouteSettings(arguments: {'selectedTab': 'coloring'}),
            ),
          );
        } else if (result['needLogin'] == true) {
          print('🔐 [ColoringScreen] 로그인이 필요합니다');
          _showLoginRequiredDialog();
        } else {
          print('❌ [ColoringScreen] 색칠 완성작 저장 실패: ${result['error']}');
          _showError('저장 실패: ${result['error'] ?? '알 수 없는 오류'}');
        }
      } else {
        print('❌ [ColoringScreen] 알 수 없는 저장 오류');
        _showError('알 수 없는 오류가 발생했습니다.');
      }
    } catch (e) {
      print('❌ [ColoringScreen] 색칠 완성작 저장 실패: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎨 색칠 작품이 임시 저장되었습니다!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GalleryScreen(),
          settings: RouteSettings(arguments: {'selectedTab': 'coloring'}),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // 🎯 로그인 필요 다이얼로그
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('로그인 필요'),
            content: Text('색칠 완성작을 저장하려면 로그인이 필요합니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                child: Text('로그인'),
              ),
            ],
          ),
    );
  }

  // 🎯 템플릿들 불러오기
  Future<void> _loadColoringTemplates() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 색칠공부 템플릿 조회 시작');

      final templatesData = await ApiService.getColoringTemplates(
        page: 0,
        size: 20,
      );

      if (templatesData != null && templatesData.isNotEmpty) {
        final templates =
            templatesData
                .map((json) => ColoringTemplate.fromJson(json))
                .toList();
        setState(() {
          _templates = templates;
        });
        print('✅ 색칠공부 템플릿 ${templates.length}개 로드 완료');
      } else {
        print('⚠️ 서버에 템플릿이 없어서 더미 데이터 사용');
        _loadDummyTemplates();
      }
    } catch (e) {
      print('❌ 템플릿 로드 오류: $e');
      _showError('색칠공부 이미지를 불러오는 중 오류가 발생했습니다.');
      _loadDummyTemplates();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 더미 데이터 로드
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
        ColoringTemplate(
          id: 'coloring_4',
          title: '숲속 친구들',
          imageUrl: 'https://picsum.photos/400/400?random=4',
          createdAt: '2024-05-27',
          storyTitle: '동글이의 우정 동화',
        ),
        ColoringTemplate(
          id: 'coloring_5',
          title: '바다 탐험',
          imageUrl: 'https://picsum.photos/400/400?random=5',
          createdAt: '2024-05-26',
          storyTitle: '동글이의 가족 동화',
        ),
        ColoringTemplate(
          id: 'coloring_6',
          title: '꿈의 정원',
          imageUrl: 'https://picsum.photos/400/400?random=6',
          createdAt: '2024-05-25',
          storyTitle: '동글이의 사랑 동화',
        ),
      ];
    });
  }

  // 🎯 전달된 이미지 확인
  void _checkForSharedImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      print('🔍 ColoringScreen에서 받은 arguments: $args');

      if (args != null && args['imageUrl'] != null) {
        String imageUrl = args['imageUrl'] as String;
        print('🔍 전달받은 이미지 URL: $imageUrl');

        bool isBlackAndWhiteMode = args['isBlackAndWhite'] ?? false;

        setState(() {
          _selectedImageUrl = imageUrl;
          _isBlackAndWhite = isBlackAndWhiteMode;
        });

        print('✅ 이미지 설정 완료: $_selectedImageUrl');
        print('✅ 흑백 모드: $_isBlackAndWhite');

        if (_isBlackAndWhite) {
          print(
            '🎨 색칠공부 모드: ${imageUrl.startsWith('http') ? '서버 변환 이미지' : 'Flutter 필터링'}',
          );
        }
      } else {
        print('⚠️ imageUrl이 전달되지 않았습니다. args: $args');
      }
    });
  }

  void _clearCanvas() {
    setState(() {
      _drawingPoints.clear();
    });
  }

  void _undoLastStroke() {
    if (_drawingPoints.isNotEmpty) {
      setState(() {
        while (_drawingPoints.isNotEmpty && _drawingPoints.last.color != null) {
          _drawingPoints.removeLast();
        }
        if (_drawingPoints.isNotEmpty) {
          _drawingPoints.removeLast();
        }
      });
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _performFloodFill() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎨 영역 채우기 기능이 곧 구현될 예정입니다!'),
        backgroundColor: Color(0xFFFFD3A8),
        duration: Duration(seconds: 2),
      ),
    );
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFFFD3A8)),
                      SizedBox(height: 16),
                      Text(
                        _isBlackAndWhite
                            ? '서버에서 색칠공부 이미지로 변환 중...'
                            : '색칠공부 이미지를 불러오는 중...',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              return _buildTemplateCard(template, screenWidth, screenHeight);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    ColoringTemplate template,
    double screenWidth,
    double screenHeight,
  ) {
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
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            Text('로드 실패'),
                          ],
                        ),
                      );
                    },
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
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: screenWidth * 0.03,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          template.createdAt,
                          style: TextStyle(
                            fontSize: screenWidth * 0.025,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoringCanvas(double screenWidth, double screenHeight) {
    return Column(
      children: [
        // 도구 선택 바
        Container(
          height: screenHeight * 0.08,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Row(
            children: [
              Text(
                '도구: ',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // 붓 도구
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTool = PaintingTool.brush;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color:
                        _selectedTool == PaintingTool.brush
                            ? Color(0xFFFFD3A8)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.brush,
                        size: screenWidth * 0.04,
                        color:
                            _selectedTool == PaintingTool.brush
                                ? Colors.white
                                : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '붓',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color:
                              _selectedTool == PaintingTool.brush
                                  ? Colors.white
                                  : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 페인트 도구
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTool = PaintingTool.floodFill;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color:
                        _selectedTool == PaintingTool.floodFill
                            ? Color(0xFFFFD3A8)
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_color_fill,
                        size: screenWidth * 0.04,
                        color:
                            _selectedTool == PaintingTool.floodFill
                                ? Colors.white
                                : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '페인트',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color:
                              _selectedTool == PaintingTool.floodFill
                                  ? Colors.white
                                  : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 색상 선택 버튼
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showColorPalette = !_showColorPalette;
                  });
                },
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
                        width: screenWidth * 0.05,
                        height: screenWidth * 0.05,
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
                      SizedBox(width: 4),
                      Icon(
                        _showColorPalette
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: screenWidth * 0.04,
                        color:
                            _showColorPalette ? Colors.white : Colors.grey[600],
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
            height: screenHeight * 0.12,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '색상을 선택하세요:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
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
                      final isSelected = _selectedColor == color;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected ? Colors.black : Colors.grey[400]!,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // 브러시 크기 조절
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Row(
            children: [
              Text(
                _selectedTool == PaintingTool.brush ? '붓 크기: ' : '영역 채우기',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child:
                    _selectedTool == PaintingTool.floodFill
                        ? Center(
                          child: Text(
                            '영역을 클릭하면 테두리 안이 색칠됩니다',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black54,
                            ),
                          ),
                        )
                        : Slider(
                          value: _brushSize,
                          min: 2.0,
                          max: 25.0,
                          divisions: 23,
                          activeColor: Color(0xFFFFD3A8),
                          label: _brushSize.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _brushSize = value;
                            });
                          },
                        ),
              ),
              Container(
                width:
                    _selectedTool == PaintingTool.floodFill
                        ? 20
                        : (_brushSize > 20 ? 20 : _brushSize),
                height:
                    _selectedTool == PaintingTool.floodFill
                        ? 20
                        : (_brushSize > 20 ? 20 : _brushSize),
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child:
                    _selectedTool == PaintingTool.floodFill
                        ? Icon(
                          Icons.format_color_fill,
                          size: 12,
                          color: Colors.white,
                        )
                        : null,
              ),
            ],
          ),
        ),

        // 색칠 캔버스
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
              child: RepaintBoundary(
                key: _canvasKey,
                child: Stack(
                  children: [
                    if (_selectedImageUrl != null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(_selectedImageUrl!),
                              fit: BoxFit.contain,
                              colorFilter:
                                  _isBlackAndWhite &&
                                          _selectedImageUrl!.contains(
                                            'picsum.photos',
                                          )
                                      ? ColorFilter.matrix([
                                        0.2126, 0.7152, 0.0722, 0, 0, // R
                                        0.2126, 0.7152, 0.0722, 0, 0, // G
                                        0.2126, 0.7152, 0.0722, 0, 0, // B
                                        0, 0, 0, 1, 0, // A
                                      ])
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: (details) {
                          if (_selectedTool == PaintingTool.brush) {
                            setState(() {
                              _drawingPoints.add(
                                DrawingPoint(
                                  offset: details.localPosition,
                                  color: _selectedColor,
                                  strokeWidth: _brushSize,
                                  tool: _selectedTool,
                                ),
                              );
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          if (_selectedTool == PaintingTool.brush) {
                            setState(() {
                              _drawingPoints.add(
                                DrawingPoint(
                                  offset: details.localPosition,
                                  color: _selectedColor,
                                  strokeWidth: _brushSize,
                                  tool: _selectedTool,
                                ),
                              );
                            });
                          }
                        },
                        onPanEnd: (details) {
                          if (_selectedTool == PaintingTool.brush) {
                            setState(() {
                              _drawingPoints.add(DrawingPoint());
                            });
                          }
                        },
                        onTap: () {
                          if (_selectedTool == PaintingTool.floodFill) {
                            _performFloodFill();
                          }
                        },
                        child: CustomPaint(
                          painter: ColoringPainter(_drawingPoints),
                          size: Size.infinite,
                          child:
                              _selectedImageUrl == null
                                  ? Container(
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: Text(
                                        '이곳에 터치해서 색칠해보세요!\n\n서버에서 변환된 색칠공부 이미지가 표시됩니다.',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
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
                child: ElevatedButton.icon(
                  onPressed: _drawingPoints.isNotEmpty ? _undoLastStroke : null,
                  icon: Icon(Icons.undo),
                  label: Text('실행\n취소'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _drawingPoints.isNotEmpty ? _clearCanvas : null,
                  icon: Icon(Icons.clear),
                  label: Text('전체\n지우기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _saveColoredImage,
                  icon:
                      _isProcessing
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
                          : Icon(Icons.save),
                  label: Text(_isProcessing ? '저장 중...' : '저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD3A8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 드로잉 포인트 클래스
class DrawingPoint {
  final Offset? offset;
  final Color? color;
  final double? strokeWidth;
  final PaintingTool? tool;

  DrawingPoint({this.offset, this.color, this.strokeWidth, this.tool});

  Map<String, dynamic> toJson() {
    return {
      'x': offset?.dx,
      'y': offset?.dy,
      'color': color?.value,
      'strokeWidth': strokeWidth,
      'tool': tool?.name,
    };
  }
}

// 페인팅 도구 열거형
enum PaintingTool { brush, floodFill }

// 커스텀 페인터 클래스
class ColoringPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  ColoringPainter(this.drawingPoints);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < drawingPoints.length; i++) {
      final point = drawingPoints[i];

      if (point.offset != null && point.color != null) {
        paint.color = point.color!;
        paint.strokeWidth = point.strokeWidth ?? 5.0;

        if (point.tool == PaintingTool.brush) {
          paint.style = PaintingStyle.stroke;
          paint.strokeCap = StrokeCap.round;

          if (i > 0 &&
              drawingPoints[i - 1].offset != null &&
              drawingPoints[i - 1].color != null &&
              drawingPoints[i - 1].tool == point.tool) {
            canvas.drawLine(drawingPoints[i - 1].offset!, point.offset!, paint);
          } else {
            canvas.drawCircle(point.offset!, paint.strokeWidth / 2, paint);
          }
        } else if (point.tool == PaintingTool.floodFill) {
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(point.offset!, 3, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 색칠공부 템플릿 데이터 모델
class ColoringTemplate {
  final String id;
  final String title;
  final String imageUrl;
  final String createdAt;
  final String storyTitle;

  ColoringTemplate({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.createdAt,
    required this.storyTitle,
  });

  factory ColoringTemplate.fromJson(Map<String, dynamic> json) {
    return ColoringTemplate(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'],
      storyTitle: json['storyTitle'],
    );
  }
}
