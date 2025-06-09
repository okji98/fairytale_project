// lib/gallery/gallery_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';
import '../../main.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryItem> _galleryItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTab = 'all'; // 'all', 'color', 'coloring'

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        // 탭 설정
        if (args['selectedTab'] != null) {
          setState(() {
            _selectedTab = args['selectedTab'] as String;
          });
        }

        // 🎯 성공 메시지 표시
        if (args['showSuccessMessage'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎨 멋진 작품이 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });

    _loadGalleryData();
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

  // 갤러리 데이터 로드
  Future<void> _loadGalleryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();

      print('🔍 갤러리 데이터 요청 시작');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/gallery/images'),
        headers: headers,
      );

      print('🔍 갤러리 응답 상태: ${response.statusCode}');
      print('🔍 갤러리 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          _galleryItems =
              responseData.map((item) => GalleryItem.fromJson(item)).toList();
        });

        print('✅ 갤러리 데이터 로드 완료: ${_galleryItems.length}개 아이템');
      } else {
        throw Exception('갤러리 데이터 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 갤러리 데이터 로드 에러: $e');
      setState(() {
        _errorMessage = '갤러리 데이터를 불러오는데 실패했습니다.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 필터링된 갤러리 아이템 가져오기
  List<GalleryItem> get _filteredItems {
    switch (_selectedTab) {
      case 'color':
        return _galleryItems
            .where((item) => item.colorImageUrl != null)
            .toList();
      case 'coloring':
        return _galleryItems
            .where((item) => item.coloringImageUrl != null)
            .toList();
      default:
        return _galleryItems;
    }
  }

  // 이미지 상세보기 모달
  void _showImageDetail(GalleryItem item) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 헤더
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.storyTitle ?? '동화 이미지',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),

                        // 이미지들
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  // 컬러 이미지
                                  if (item.colorImageUrl != null) ...[
                                    Text(
                                      '컬러 이미지',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item.colorImageUrl!,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 200,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 200,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: Icon(Icons.error),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                  ],

                                  // 색칠한 이미지
                                  if (item.coloringImageUrl != null) ...[
                                    Text(
                                      '색칠한 이미지',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item.coloringImageUrl!,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 200,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 200,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: Icon(Icons.error),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final primaryColor = Color(0xFFF6B756);

    return BaseScaffold(
      background: Image.asset('assets/bg_image.png', fit: BoxFit.cover),
      child: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      '갤러리',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadGalleryData,
                  ),
                ],
              ),
            ),

            // 탭 버튼들
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('전체', 'all')),
                  SizedBox(width: 8),
                  Expanded(child: _buildTabButton('컬러', 'color')),
                  SizedBox(width: 8),
                  Expanded(child: _buildTabButton('색칠', 'coloring')),
                ],
              ),
            ),

            SizedBox(height: 16),

            // 컨텐츠 영역
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadGalleryData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                              child: Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                      : _filteredItems.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '아직 이미지가 없어요',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '동화를 만들고 이미지를 생성해보세요!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildGalleryCard(_filteredItems[index]);
                          },
                        ),
                      ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 탭 버튼 위젯
  Widget _buildTabButton(String title, String tabKey) {
    final isSelected = _selectedTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabKey;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF6B756) : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? Color(0xFFF6B756) : Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // 갤러리 카드 위젯
  Widget _buildGalleryCard(GalleryItem item) {
    // 표시할 이미지 결정 (우선순위: 색칠한 이미지 > 컬러 이미지)
    String? displayImageUrl = item.coloringImageUrl ?? item.colorImageUrl;

    return GestureDetector(
      onTap: () => _showImageDetail(item),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 메인 이미지
              if (displayImageUrl != null)
                Image.network(
                  displayImageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF6B756),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.image, color: Colors.grey[600], size: 40),
                  ),
                ),

              // 오버레이 정보
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.storyTitle != null)
                        Text(
                          item.storyTitle!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (item.createdAt != null)
                        Text(
                          _formatDate(item.createdAt!),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 타입 인디케이터
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(item),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeText(item),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 타입별 색상
  Color _getTypeColor(GalleryItem item) {
    if (item.coloringImageUrl != null && item.colorImageUrl != null) {
      return Color(0xFF9C27B0); // 보라색 (둘 다)
    } else if (item.coloringImageUrl != null) {
      return Color(0xFF4CAF50); // 녹색 (색칠)
    } else {
      return Color(0xFF2196F3); // 파란색 (컬러)
    }
  }

  // 타입별 텍스트
  String _getTypeText(GalleryItem item) {
    if (item.coloringImageUrl != null && item.colorImageUrl != null) {
      return '완성';
    } else if (item.coloringImageUrl != null) {
      return '색칠';
    } else {
      return '컬러';
    }
  }
}

// 갤러리 아이템 모델
class GalleryItem {
  final int storyId;
  final String? storyTitle;
  final String? colorImageUrl;
  final String? coloringImageUrl;
  final DateTime? createdAt;

  GalleryItem({
    required this.storyId,
    this.storyTitle,
    this.colorImageUrl,
    this.coloringImageUrl,
    this.createdAt,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      storyId: json['storyId'] ?? json['story_id'] ?? 0,
      storyTitle: json['storyTitle'] ?? json['story_title'],
      colorImageUrl: json['colorImageUrl'] ?? json['color_image_url'],
      coloringImageUrl: json['coloringImageUrl'] ?? json['coloring_image_url'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ??
                  DateTime.tryParse(json['created_at'])
              : null,
    );
  }
}
