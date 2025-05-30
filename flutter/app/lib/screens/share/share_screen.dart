// lib/screens/share/share_screen.dart
import 'package:flutter/material.dart';
import '../../main.dart';

class ShareScreen extends StatefulWidget {
  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> with TickerProviderStateMixin {
  // 데이터 관리
  List<StoryPost> _posts = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  // 애니메이션
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  // 페이지 컨트롤러
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPosts();
    _checkForSharedVideo();
  }

  void _initAnimations() {
    _refreshController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // TODO: Spring Boot API에서 기록일지 게시물들 불러오기
  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      // final response = await http.get(
      //   Uri.parse('$baseUrl/api/share/posts'),
      //   headers: {'Authorization': 'Bearer $accessToken'},
      // );
      //
      // if (response.statusCode == 200) {
      //   final List<dynamic> postsJson = json.decode(response.body);
      //   setState(() {
      //     _posts = postsJson.map((json) => StoryPost.fromJson(json)).toList();
      //   });
      // } else {
      //   throw Exception('게시물을 불러오는데 실패했습니다.');
      // }

      // 현재는 더미 데이터
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _posts = [
          StoryPost(
            id: 'post_1',
            userName: '동글이 엄마',
            userAvatar: 'https://storage.bucket.com/avatars/mom.jpg',
            storyTitle: '동글이의 자연 동화',
            videoUrl: 'https://storage.bucket.com/videos/story_1.mp4',
            thumbnailUrl: 'https://storage.bucket.com/thumbnails/story_1.jpg',
            caption: '오늘 동글이와 함께 만든 특별한 동화예요! 🌸 토끼와 꽃밭에서 벌어지는 모험 이야기입니다. 아이가 너무 좋아해서 계속 보고 있어요 ❤️',
            likesCount: 24,
            commentsCount: 5,
            createdAt: '2시간 전',
            isLiked: false,
          ),
          StoryPost(
            id: 'post_2',
            userName: '수민이 아빠',
            userAvatar: 'https://storage.bucket.com/avatars/dad.jpg',
            storyTitle: '수민이의 우주 모험',
            videoUrl: 'https://storage.bucket.com/videos/story_2.mp4',
            thumbnailUrl: 'https://storage.bucket.com/thumbnails/story_2.jpg',
            caption: '수민이와 함께 우주여행 이야기를 만들었어요 🚀 아이의 상상력이 정말 놀라워요!',
            likesCount: 18,
            commentsCount: 3,
            createdAt: '5시간 전',
            isLiked: true,
          ),
          StoryPost(
            id: 'post_3',
            userName: '하은이 할머니',
            userAvatar: 'https://storage.bucket.com/avatars/grandma.jpg',
            storyTitle: '하은이의 마법 동화',
            videoUrl: 'https://storage.bucket.com/videos/story_3.mp4',
            thumbnailUrl: 'https://storage.bucket.com/thumbnails/story_3.jpg',
            caption: '손녀와 함께 마법의 성 이야기를 만들었답니다 ✨ 옛날 이야기 같아서 정말 재밌어요',
            likesCount: 31,
            commentsCount: 8,
            createdAt: '1일 전',
            isLiked: false,
          ),
        ];
      });
    } catch (e) {
      _showError('게시물을 불러오는 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TODO: Stories에서 전달된 비디오 확인 및 업로드
  void _checkForSharedVideo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['videoUrl'] != null) {
        _uploadSharedVideo(args);
      }
    });
  }

  // TODO: Stories에서 온 비디오 업로드
  Future<void> _uploadSharedVideo(Map<String, dynamic> videoData) async {
    setState(() => _isUploading = true);

    try {
      // final uploadData = {
      //   'videoUrl': videoData['videoUrl'],
      //   'storyTitle': videoData['storyTitle'],
      //   'storyContent': videoData['storyContent'],
      //   'audioUrl': videoData['audioUrl'],
      //   'imageUrl': videoData['imageUrl'],
      //   'userId': 'current_user_id',
      //   'caption': '', // 사용자가 입력할 캡션
      // };
      //
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/share/upload'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $accessToken',
      //   },
      //   body: json.encode(uploadData),
      // );
      //
      // if (response.statusCode == 200) {
      //   await _loadPosts(); // 게시물 목록 새로고침
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('동화가 기록일지에 공유되었습니다!')),
      //   );
      // } else {
      //   throw Exception('업로드에 실패했습니다.');
      // }

      // 현재는 더미 업로드
      await Future.delayed(Duration(seconds: 3));

      // 새 게시물을 맨 위에 추가
      final newPost = StoryPost(
        id: 'post_new_${DateTime.now().millisecondsSinceEpoch}',
        userName: '동글이 엄마',
        userAvatar: 'https://storage.bucket.com/avatars/mom.jpg',
        storyTitle: videoData['storyTitle'] ?? '새로운 동화',
        videoUrl: videoData['videoUrl'] ?? '',
        thumbnailUrl: 'https://storage.bucket.com/thumbnails/new.jpg',
        caption: '방금 만든 새로운 동화를 공유해요! 🎉',
        likesCount: 0,
        commentsCount: 0,
        createdAt: '방금 전',
        isLiked: false,
      );

      setState(() {
        _posts.insert(0, newPost);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 동화가 기록일지에 공유되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('업로드 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // TODO: 게시물 좋아요/좋아요 취소
  Future<void> _toggleLike(String postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isLiked = post.isLiked;

    // 낙관적 업데이트 (UI 먼저 변경)
    setState(() {
      _posts[postIndex] = post.copyWith(
        isLiked: !isLiked,
        likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });

    try {
      // final response = await http.post(
      //   Uri.parse('$baseUrl/api/share/posts/$postId/like'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $accessToken',
      //   },
      //   body: json.encode({'isLiked': !isLiked}),
      // );
      //
      // if (response.statusCode != 200) {
      //   throw Exception('좋아요 처리에 실패했습니다.');
      // }
    } catch (e) {
      // 실패 시 원상복구
      setState(() {
        _posts[postIndex] = post;
      });
      _showError('좋아요 처리 중 오류가 발생했습니다.');
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

  Future<void> _onRefresh() async {
    _refreshController.forward();
    await _loadPosts();
    _refreshController.reset();
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
                      '우리의 기록일지',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // 새 게시물 작성 버튼
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/stories');
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF9F8D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: screenWidth * 0.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 업로드 중일 때 진행 표시
            if (_isUploading)
              Container(
                padding: EdgeInsets.all(16),
                color: Color(0xFFFF9F8D).withOpacity(0.1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9F8D)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '동화를 기록일지에 업로드하는 중...',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Color(0xFFFF9F8D),
                      ),
                    ),
                  ],
                ),
              ),

            // 게시물 피드
            Expanded(
              child: _isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFFF9F8D),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '기록일지를 불러오는 중...',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
                  : _posts.isEmpty
                  ? _buildEmptyState(screenWidth, screenHeight)
                  : RefreshIndicator(
                onRefresh: _onRefresh,
                color: Color(0xFFFF9F8D),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(_posts[index], screenWidth, screenHeight);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: screenWidth * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '아직 공유된 동화가 없어요',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 동화를 만들어서 공유해보세요!',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.black38,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/stories');
            },
            icon: Icon(Icons.add),
            label: Text('동화 만들기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF9F8D),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(StoryPost post, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 게시물 헤더 (프로필 정보)
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // 프로필 아바타
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    // TODO: 실제 프로필 이미지
                    // image: DecorationImage(
                    //   image: NetworkImage(post.userAvatar),
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        post.createdAt,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // 더보기 메뉴
                IconButton(
                  onPressed: () {
                    _showPostMenu(post);
                  },
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.black54,
                    size: screenWidth * 0.05,
                  ),
                ),
              ],
            ),
          ),

          // 동화 제목
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFF9F8D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.storyTitle,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9F8D),
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          // 비디오 썸네일
          Container(
            height: screenHeight * 0.3,
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // 썸네일 이미지
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library,
                            size: screenWidth * 0.15,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '동화 비디오',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // TODO: 실제 썸네일 이미지
                    // child: Image.network(
                    //   post.thumbnailUrl,
                    //   fit: BoxFit.cover,
                    //   loadingBuilder: (context, child, loadingProgress) {
                    //     if (loadingProgress == null) return child;
                    //     return Center(child: CircularProgressIndicator());
                    //   },
                    // ),
                  ),
                  // 재생 버튼 오버레이
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _playVideo(post);
                          },
                          child: Container(
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Color(0xFFFF9F8D),
                              size: screenWidth * 0.08,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 좋아요, 댓글 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 좋아요 버튼
                GestureDetector(
                  onTap: () => _toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.black54,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                // 댓글 버튼
                GestureDetector(
                  onTap: () => _showComments(post),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.black54,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // 공유 버튼
                GestureDetector(
                  onTap: () => _sharePost(post),
                  child: Icon(
                    Icons.share,
                    color: Colors.black54,
                    size: screenWidth * 0.06,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // 캡션
          if (post.caption.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.caption,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _playVideo(StoryPost post) {
    // TODO: 비디오 플레이어 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: post.videoUrl,
          title: post.storyTitle,
        ),
      ),
    );
  }

  void _showPostMenu(StoryPost post) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.report),
                title: Text('신고하기'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 신고 기능
                },
              ),
              ListTile(
                leading: Icon(Icons.block),
                title: Text('차단하기'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 차단 기능
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComments(StoryPost post) {
    // TODO: 댓글 화면 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: CommentsScreen(postId: post.id),
        );
      },
    );
  }

  void _sharePost(StoryPost post) {
    // TODO: 외부 공유 기능 (카카오톡, 인스타그램 등)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('공유 기능이 곧 추가될 예정입니다!'),
        backgroundColor: Color(0xFFFF9F8D),
      ),
    );
  }
}

// 게시물 데이터 모델
class StoryPost {
  final String id;
  final String userName;
  final String userAvatar;
  final String storyTitle;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final String createdAt;
  final bool isLiked;

  StoryPost({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.storyTitle,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.isLiked,
  });

  factory StoryPost.fromJson(Map<String, dynamic> json) {
    return StoryPost(
      id: json['id'],
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      storyTitle: json['storyTitle'],
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      caption: json['caption'],
      likesCount: json['likesCount'],
      commentsCount: json['commentsCount'],
      createdAt: json['createdAt'],
      isLiked: json['isLiked'],
    );
  }

  StoryPost copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    String? storyTitle,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? likesCount,
    int? commentsCount,
    String? createdAt,
    bool? isLiked,
  }) {
    return StoryPost(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      storyTitle: storyTitle ?? this.storyTitle,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

// TODO: 비디오 플레이어 화면 (별도 구현 필요)
class VideoPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    required this.videoUrl,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_fill,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              '비디오 플레이어',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'TODO: 실제 비디오 플레이어 구현',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: 댓글 화면 (별도 구현 필요)
class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({required this.postId, Key? key}) : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // TODO: Spring Boot API에서 댓글 불러오기
  Future<void> _loadComments() async {
    // 더미 댓글 데이터
    setState(() {
      _comments = [
        Comment(
          id: 'comment_1',
          userName: '수민이 엄마',
          userAvatar: 'https://storage.bucket.com/avatars/user1.jpg',
          content: '정말 아름다운 동화네요! 우리 아이도 좋아할 것 같아요 ❤️',
          createdAt: '1시간 전',
        ),
        Comment(
          id: 'comment_2',
          userName: '지훈이 아빠',
          userAvatar: 'https://storage.bucket.com/avatars/user2.jpg',
          content: '목소리가 너무 좋아요. 어떤 성우분인가요?',
          createdAt: '30분 전',
        ),
      ];
    });
  }

  // TODO: 댓글 작성
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = Comment(
      id: 'comment_new_${DateTime.now().millisecondsSinceEpoch}',
      userName: '나',
      userAvatar: 'https://storage.bucket.com/avatars/me.jpg',
      content: _commentController.text.trim(),
      createdAt: '방금 전',
    );

    setState(() {
      _comments.insert(0, newComment);
      _commentController.clear();
    });

    // TODO: API 호출
    // final response = await http.post(
    //   Uri.parse('$baseUrl/api/share/posts/${widget.postId}/comments'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $accessToken',
    //   },
    //   body: json.encode({'content': newComment.content}),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // 헤더
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Text(
                '댓글',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                '${_comments.length}개',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),

        // 댓글 목록
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 프로필 아바타
                    Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: screenWidth * 0.05,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.userName,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                comment.createdAt,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 댓글 입력
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: _postComment,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9F8D),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
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

// 댓글 데이터 모델
class Comment {
  final String id;
  final String userName;
  final String userAvatar;
  final String content;
  final String createdAt;

  Comment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      content: json['content'],
      createdAt: json['createdAt'],
    );
  }
}