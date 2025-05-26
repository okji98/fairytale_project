// Flutter의 Cupertino 위젯을 사용하기 위해 import
import 'package:flutter/cupertino.dart';
// Flutter의 Material 디자인 위젯을 사용하기 위해 import
import 'package:flutter/material.dart';
import 'package:project_1/story_list_screen.dart';

// AI 동화 생성 페이지 위젯을 가져옵니다
import 'aistorypage.dart';
// 로그인 화면 위젯을 가져옵니다
import 'loginscreen.dart';
// 마이페이지 화면 위젯을 가져옵니다
import 'mypagescreen.dart';
// 커뮤니티 업로드 화면 위젯을 가져옵니다
import 'upload_board_screen.dart';

// 메인 화면을 StatefulWidget으로 선언합니다
class MainScreen extends StatefulWidget {
  // 생성자에 super.key를 전달합니다
  const MainScreen({super.key});
  @override
  // 상태 객체를 생성합니다
  State<MainScreen> createState() => _MainScreenState();
}

// MainScreen의 상태를 관리하는 클래스입니다
class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 BottomNavigationBar의 인덱스를 저장합니다
  int _currentIndex = 0;
  // 홈 화면 이미지 애니메이션 토글 상태를 저장합니다
  bool _mainMoved = false;

  // 각 탭에 대응하는 페이지 리스트를 정의합니다
  final List<Widget> _pages = [
    // 인덱스 0: 홈 화면은 별도의 위젯을 사용합니다
    const SizedBox.shrink(),
    // 인덱스 1: 동화 리스트 화면(플레이스홀더)
    const StoryListScreen(),
    // 인덱스 2: 커뮤니티 업로드 페이지
    const UploadBoardScreen(),
    // 인덱스 3: 마이페이지 화면
    const MyPageScreen(),
  ];

  // 홈 탭 전용 뷰를 빌드하는 메서드입니다
  Widget _buildHomeView() {
    // Stack을 사용해 이미지와 버튼을 겹쳐 배치합니다
    return Stack(
      children: [
        // AnimatedAlign을 사용해 이미지 위치 애니메이션을 처리합니다
        AnimatedAlign(
          // _mainMoved 상태에 따라 위치를 변경합니다
          alignment: _mainMoved ? Alignment.topCenter : Alignment.center,
          // 애니메이션 지속 시간을 설정합니다
          duration: const Duration(milliseconds: 500),
          // 애니메이션 커브를 설정합니다
          curve: Curves.easeInOut,
          // 제스처 감지를 위해 GestureDetector로 래핑합니다
          child: GestureDetector(
            // 탭 시 _mainMoved를 토글합니다
            onTap: () => setState(() => _mainMoved = !_mainMoved),
            // 메인 이미지를 로드합니다
            child: Image.asset(
              'assets/main.png',
              width: 400,
              height: 400,
            ),
          ),
        ),
        // AI 동화 구현 버튼 자리에 이미지를 사용하도록 Positioned로 배치합니다
        Positioned(
          // 상단으로부터 16픽셀 위치에 배치합니다
          top: 4,
          // 우측으로부터 16픽셀 위치에 배치합니다
          right: 16,
          // 버튼 역할을 하는 InkWell 위젯입니다
          child: InkWell(
            // 탭 시 AIStoryPage로 네비게이션합니다
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIStoryPage()),
              );
            },
            // 버튼 디테일로 사용할 이미지를 Ink.image로 표시합니다
            child: Ink.image(
              // assets 폴더에 저장된 aiimage.png 파일 경로
              image: const AssetImage('assets/aiimage.png'),
              // 가로 크기를 설정합니다
              width: 100,
              // 세로 크기를 설정합니다
              height: 100,
              // 이미지를 영역에 맞게 자릅니다
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  @override
  // 위젯 빌드 메서드입니다
  Widget build(BuildContext context) {
    // Scaffold로 기본 레이아웃을 구성합니다
    return Scaffold(
      // 배경색을 핑크톤으로 설정합니다
      backgroundColor: Colors.pink[50],
      // 앱바를 설정합니다
      appBar: AppBar(
        // 앱바 배경색을 흰색으로 설정합니다
        backgroundColor: Colors.white,
        // leading 영역 너비를 100으로 설정합니다
        leadingWidth: 100,
        // leading에 로고 클릭 시 홈으로 돌아오는 기능을 추가합니다
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            // 탭 시 _currentIndex를 0으로 설정해 홈 탭으로 이동합니다
            onTap: () => setState(() => _currentIndex = 0),
            // 클릭 시 스플래시 색을 설정합니다
            splashColor: Colors.white.withOpacity(0.5),
            // 클릭 영역을 둥글게 만듭니다
            borderRadius: BorderRadius.circular(70),
            // 로고 이미지를 패딩으로 감싸서 표시합니다
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset(
                'assets/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // 제목 영역을 빈 공간으로 설정합니다
        title: const SizedBox.shrink(),
        // 로그인 버튼을 actions에 추가합니다
        actions: [
          TextButton(
            // 탭 시 로그인 화면으로 이동합니다
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            // 버튼 텍스트와 스타일을 설정합니다
            child: const Text('LOGIN', style: TextStyle(color: Colors.black)),
          ),
        ],
        // 앱바 그림자를 제거합니다
        elevation: 0,
      ),
      // body에 현재 인덱스에 따라 홈 뷰 또는 다른 페이지를 렌더링합니다
      body: _currentIndex == 0 ? _buildHomeView() : _pages[_currentIndex],
      // 바텀 네비게이션 바를 설정합니다
      bottomNavigationBar: BottomNavigationBar(
        // 현재 선택된 인덱스를 지정합니다
        currentIndex: _currentIndex,
        // 탭 변경 시 _currentIndex를 업데이트합니다
        onTap: (idx) => setState(() => _currentIndex = idx),
        // 각 탭 아이콘과 레이블을 설정합니다
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈화면'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: '동화세상'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '커뮤니티'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
        // 선택된 아이템 색상을 검정색으로 설정합니다
        selectedItemColor: Colors.pinkAccent,
        // 선택되지 않은 아이템 색상을 회색으로 설정합니다
        unselectedItemColor: Colors.grey,
        // 배경색을 흰색으로 설정합니다
        backgroundColor: Colors.white,
        // 그림자를 제거합니다
        elevation: 0,
      ),
    );
  }
}
