// lib/coloring_screen.dart

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class ColoringScreen extends StatefulWidget {
  @override
  _ColoringScreenState createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  // 색칠공부 데이터 관리
  List<ColoringTemplate> _templates = [];
  String? _selectedImageUrl;
  Color _selectedColor = Colors.red;
  double _brushSize = 5.0;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _showColorPalette = false; // 색상 팔레트 표시 여부
  PaintingTool _selectedTool = PaintingTool.brush; // 선택된 도구

  // 페인팅 관련
  List<DrawingPoint> _drawingPoints = [];
  ui.Image? _backgroundImage; // 배경 이미지
  Uint8List? _pixelData; // 이미지 픽셀 데이터

  // 색상 팔레트 (더 많은 색상 추가)
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

  // TODO: Spring Boot API에서 흑백 이미지들 불러오기
  Future<void> _loadColoringTemplates() async {
    setState(() => _isLoading = true);

    try {
      // final response = await http.get(
      //   Uri.parse('$baseUrl/api/coloring/templates'),
      //   headers: {'Authorization': 'Bearer $accessToken'},
      // );
      //
      // if (response.statusCode == 200) {
      //   final List<dynamic> templatesJson = json.decode(response.body);
      //   setState(() {
      //     _templates = templatesJson.map((json) => ColoringTemplate.fromJson(json)).toList();
      //   });
      // } else {
      //   throw Exception('색칠공부 이미지를 불러오는데 실패했습니다.');
      // }

      // 현재는 저장된 흑백 이미지들의 더미 데이터
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _templates = [
          ColoringTemplate(
            id: 'coloring_1',
            title: '토끼와 꽃밭',
            imageUrl: 'https://storage.bucket.com/coloring/rabbit_flowers_bw.jpg',
            createdAt: '2024-05-30',
            storyTitle: '동글이의 자연 동화',
          ),
          ColoringTemplate(
            id: 'coloring_2',
            title: '마법의 성 모험',
            imageUrl: 'https://storage.bucket.com/coloring/castle_adventure_bw.jpg',
            createdAt: '2024-05-29',
            storyTitle: '동글이의 용기 동화',
          ),
          ColoringTemplate(
            id: 'coloring_3',
            title: '우주 여행',
            imageUrl: 'https://storage.bucket.com/coloring/space_travel_bw.jpg',
            createdAt: '2024-05-28',
            storyTitle: '동글이의 도전 동화',
          ),
          ColoringTemplate(
            id: 'coloring_4',
            title: '숲속 친구들',
            imageUrl: 'https://storage.bucket.com/coloring/forest_friends_bw.jpg',
            createdAt: '2024-05-27',
            storyTitle: '동글이의 우정 동화',
          ),
          ColoringTemplate(
            id: 'coloring_5',
            title: '바다 탐험',
            imageUrl: 'https://storage.bucket.com/coloring/ocean_explore_bw.jpg',
            createdAt: '2024-05-26',
            storyTitle: '동글이의 가족 동화',
          ),
          ColoringTemplate(
            id: 'coloring_6',
            title: '꿈의 정원',
            imageUrl: 'https://storage.bucket.com/coloring/dream_garden_bw.jpg',
            createdAt: '2024-05-25',
            storyTitle: '동글이의 사랑 동화',
          ),
        ];
      });
    } catch (e) {
      _showError('색칠공부 이미지를 불러오는 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TODO: Stories에서 전달된 이미지 확인
  void _checkForSharedImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['imageUrl'] != null) {
        setState(() {
          _selectedImageUrl = args['imageUrl'];
        });
      }
    });
  }

  // TODO: Spring Boot API로 색칠한 이미지 저장
  Future<void> _saveColoredImage() async {
    if (_selectedImageUrl == null) return;

    setState(() => _isProcessing = true);

    try {
      // final coloringData = {
      //   'originalImageUrl': _selectedImageUrl,
      //   'drawingPoints': _drawingPoints.map((point) => point.toJson()).toList(),
      //   'userId': 'current_user_id',
      //   'timestamp': DateTime.now().toIso8601String(),
      // };
      //
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/coloring/save'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $accessToken',
      //   },
      //   body: json.encode(coloringData),
      // );
      //
      // if (response.statusCode == 200) {
      //   final responseData = json.decode(response.body);
      //   final String savedImageUrl = responseData['savedImageUrl']; // S3 저장된 URL
      //
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('작품이 갤러리에 저장되었습니다!')),
      //   );
      // } else {
      //   throw Exception('저장에 실패했습니다.');
      // }

      // 현재는 더미 저장
      await Future.delayed(Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎨 멋진 작품이 갤러리에 저장되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('저장 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _clearCanvas() {
    setState(() {
      _drawingPoints.clear();
    });
  }

  void _undoLastStroke() {
    if (_drawingPoints.isNotEmpty) {
      setState(() {
        // 마지막 연속된 스트로크 제거
        while (_drawingPoints.isNotEmpty && _drawingPoints.last.color != null) {
          _drawingPoints.removeLast();
        }
        if (_drawingPoints.isNotEmpty) {
          _drawingPoints.removeLast(); // null 포인트도 제거
        }
      });
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

  // TODO: 플러드 필(영역 채우기) 기능 구현
  void _performFloodFill() {
    // 현재는 시뮬레이션
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎨 영역 채우기 기능이 곧 구현될 예정입니다!'),
        backgroundColor: Color(0xFFFFD3A8),
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: 실제 플러드 필 알고리즘 구현
    // 1. 터치한 위치의 색상 확인
    // 2. 같은 색상으로 연결된 영역 찾기
    // 3. 해당 영역을 선택된 색상으로 채우기
    //
    // Future<void> _floodFillArea(Offset tapPosition) async {
    //   if (_backgroundImage == null) return;
    //
    //   // 이미지를 픽셀 데이터로 변환
    //   final ByteData? byteData = await _backgroundImage!.toByteData();
    //   if (byteData == null) return;
    //
    //   final pixels = byteData.buffer.asUint8List();
    //   final width = _backgroundImage!.width;
    //   final height = _backgroundImage!.height;
    //
    //   // 터치 위치를 픽셀 좌표로 변환
    //   final x = (tapPosition.dx * width / canvasWidth).round();
    //   final y = (tapPosition.dy * height / canvasHeight).round();
    //
    //   // 플러드 필 알고리즘 실행
    //   _floodFillAlgorithm(pixels, width, height, x, y, _selectedColor);
    //
    //   // 결과를 화면에 반영
    //   setState(() {
    //     // 채워진 영역을 DrawingPoint로 변환하여 추가
    //   });
    // }
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
                      CircularProgressIndicator(
                        color: Color(0xFFFFD3A8),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '색칠공부 이미지를 불러오는 중...',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_selectedImageUrl != null)
            // 색칠하기 화면
              Expanded(
                child: _buildColoringCanvas(screenWidth, screenHeight),
              )
            else
            // 템플릿 선택 화면
              Expanded(
                child: _buildTemplateGrid(screenWidth, screenHeight),
              ),
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
          // 안내 텍스트
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
                  child:                   Text(
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

          // 색칠 이미지 그리드
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

  Widget _buildTemplateCard(ColoringTemplate template, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImageUrl = template.imageUrl;
          _drawingPoints.clear(); // 새 이미지 선택 시 드로잉 포인트 초기화
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
            // 이미지 미리보기
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: screenWidth * 0.12,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '흑백 이미지',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: screenWidth * 0.025,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // TODO: 실제 이미지 로드
                  // child: Image.network(
                  //   template.imageUrl,
                  //   fit: BoxFit.cover,
                  //   loadingBuilder: (context, child, loadingProgress) {
                  //     if (loadingProgress == null) return child;
                  //     return Center(
                  //       child: CircularProgressIndicator(
                  //         color: Color(0xFFFFD3A8),
                  //       ),
                  //     );
                  //   },
                  //   errorBuilder: (context, error, stackTrace) {
                  //     return Center(
                  //       child: Column(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Icon(Icons.error, color: Colors.red),
                  //           Text('로드 실패'),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // ),
                ),
              ),
            ),

            // 템플릿 정보
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
                    color: _selectedTool == PaintingTool.brush
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
                        color: _selectedTool == PaintingTool.brush
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '붓',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: _selectedTool == PaintingTool.brush
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 페인트 도구 (플러드 필)
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
                    color: _selectedTool == PaintingTool.floodFill
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
                        color: _selectedTool == PaintingTool.floodFill
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '페인트',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: _selectedTool == PaintingTool.floodFill
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
                    color: _showColorPalette ? Color(0xFFFFD3A8) : Colors.grey[300],
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
                          color: _showColorPalette ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        _showColorPalette ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: screenWidth * 0.04,
                        color: _showColorPalette ? Colors.white : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 색상 팔레트 (접을 수 있음)
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
                              color: isSelected ? Colors.black : Colors.grey[400]!,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ] : null,
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
                child: _selectedTool == PaintingTool.floodFill
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
                width: _selectedTool == PaintingTool.floodFill ? 20 : (_brushSize > 20 ? 20 : _brushSize),
                height: _selectedTool == PaintingTool.floodFill ? 20 : (_brushSize > 20 ? 20 : _brushSize),
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: _selectedTool == PaintingTool.floodFill
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

        // 색칠 캔버스 (실제 페인팅 기능)
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
                      _drawingPoints.add(DrawingPoint()); // null point to separate strokes
                    });
                  }
                },
                onTap: () {
                  if (_selectedTool == PaintingTool.floodFill) {
                    // TODO: 플러드 필 구현
                    _performFloodFill();
                  }
                },
                child: CustomPaint(
                  painter: ColoringPainter(_drawingPoints),
                  size: Size.infinite,
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        '이곳에 터치해서 색칠해보세요!\n\n선택된 S3 이미지가 배경으로 표시됩니다.',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // TODO: 배경에 S3 이미지 표시
                    // decoration: BoxDecoration(
                    //   image: DecorationImage(
                    //     image: NetworkImage(_selectedImageUrl!),
                    //     fit: BoxFit.contain,
                    //   ),
                    // ),
                  ),
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
              // 되돌리기 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImageUrl = null;
                      _drawingPoints.clear();
                    });
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('다시 선택'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              SizedBox(width: screenWidth * 0.02),

              // 실행 취소 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _drawingPoints.isNotEmpty ? _undoLastStroke : null,
                  icon: Icon(Icons.undo),
                  label: Text('실행 취소'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              SizedBox(width: screenWidth * 0.02),

              // 전체 지우기 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _drawingPoints.isNotEmpty ? _clearCanvas : null,
                  icon: Icon(Icons.clear),
                  label: Text('전체 지우기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              SizedBox(width: screenWidth * 0.02),

              // 저장 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _saveColoredImage,
                  icon: _isProcessing
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
enum PaintingTool {
  brush,      // 붓 (드래그하여 그리기)
  floodFill,  // 페인트 (영역 채우기)
}

// 커스텀 페인터 클래스
class ColoringPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  ColoringPainter(this.drawingPoints);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < drawingPoints.length; i++) {
      final point = drawingPoints[i];

      if (point.offset != null && point.color != null) {
        paint.color = point.color!;
        paint.strokeWidth = point.strokeWidth ?? 5.0;

        // 도구에 따라 스타일 변경
        if (point.tool == PaintingTool.brush) {
          paint.style = PaintingStyle.stroke;
          paint.strokeCap = StrokeCap.round;

          if (i > 0 &&
              drawingPoints[i - 1].offset != null &&
              drawingPoints[i - 1].color != null &&
              drawingPoints[i - 1].tool == point.tool) {
            // 연속된 붓 터치를 선으로 연결
            canvas.drawLine(drawingPoints[i - 1].offset!, point.offset!, paint);
          } else {
            // 첫 번째 점은 원으로 그리기
            canvas.drawCircle(point.offset!, paint.strokeWidth / 2, paint);
          }
        } else if (point.tool == PaintingTool.floodFill) {
          // 플러드 필은 별도로 처리 (여기서는 표시만)
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
  final String imageUrl; // 흑백 이미지 URL
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