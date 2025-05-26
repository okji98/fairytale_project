// Flutter의 Material 디자인 위젯을 사용하기 위해 import
import 'package:flutter/material.dart';

// 동화 리스트 화면을 StatefulWidget으로 선언합니다
class StoryListScreen extends StatefulWidget {
  // 생성자에서 super.key를 전달합니다
  const StoryListScreen({super.key});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

// StoryListScreen의 상태를 관리하는 클래스입니다
class _StoryListScreenState extends State<StoryListScreen> {
  // 예시로 사용할 동화 제목 리스트를 정의합니다
  final List<String> _storyTitles = [
    '첫 번째 동화',
    '마법의 숲 이야기',
    '별을 찾아서',
    '용감한 공주와 기사',
  ];

  @override
  Widget build(BuildContext context) {
    // Scaffold로 기본 레이아웃을 구성합니다
    return Scaffold(
      // 앱바에 제목을 설정합니다
      appBar: AppBar(
        title: const Text('동화 리스트'),
        backgroundColor: Colors.pinkAccent,
      ),
      // 본문에 ListView를 사용해 동화 목록을 표시합니다
      body: ListView.builder(
        // 리스트 아이템 개수를 _storyTitles 길이만큼 설정합니다
        itemCount: _storyTitles.length,
        // 각 아이템 빌더
        itemBuilder: (context, index) {
          // Card로 감싸 보기 좋게 디자인합니다
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              // 동화 제목 텍스트를 표시합니다
              title: Text(_storyTitles[index]),
              // 화살표 아이콘으로 클릭 가능함을 표시합니다
              trailing: const Icon(Icons.arrow_forward_ios),
              // 탭 시 상세 페이지로 이동(추후 구현)
              onTap: () {
                // TODO: 동화 상세 페이지로 네비게이션 구현
              },
            ),
          );
        },
      ),
    );
  }
}
