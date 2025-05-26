import 'package:flutter/material.dart';

class AIStoryPage extends StatefulWidget {
  const AIStoryPage({super.key});

  @override
  State<AIStoryPage> createState() => _AIStoryPageState();
}

class _AIStoryPageState extends State<AIStoryPage> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  String _selectedTheme = '일반';
  String _colorMode = '컬러';
  String _story = '';
  String _imageUrl = ''; // 이미지 URL 받아올 예정

  @override
  void dispose() {
    _keywordController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _generateStory() {
    setState(() {
      _story =
      '[${_selectedTheme}] 테마, "${_keywordController.text}" 키워드로 ${_lengthController.text}자 분량의 동화를 생성합니다.\n\n동화 내용 예시...';
    });
  }

  void _readStory() {
    // TODO: TTS 호출 로직
    print('동화 읽기 (TTS)');
  }

  void _generateImage() {
    setState(() {
      _imageUrl =
      'https://cdn.pixabay.com/photo/2021/05/15/10/55/fantasy-6255485_1280.jpg';
    });
  }

  void _shareContent() {
    // TODO: 공유 로직 (URL, 카카오톡 등)
    print('공유하기');
  }

  void _downloadImage() {
    // TODO: 이미지 다운로드 로직
    print('이미지 다운로드');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('AI 동화 생성기'),
          backgroundColor: const Color(0xFFE59C9C),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 테마 선택
                const Text('테마 선택'),
            DropdownButton<String>(
                value: _selectedTheme,
                items: ['일반', '모험', '공포', '감동', '동물']
                .map((theme) =>
            DropdownMenuItem(value: theme, child: Text(theme)))
        .toList(),
    onChanged: (value) => setState(() => _selectedTheme = value!),
    ),
    const SizedBox(height: 12),

    // 키워드 입력
    TextField(
    controller: _keywordController,
    decoration: const InputDecoration(
    labelText: '키워드 입력',
    border: OutlineInputBorder(),
    ),
    ),
    const SizedBox(height: 12),

    // 길이 입력
    TextField(
    controller: _lengthController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
    labelText: '글 길이(자) 입력',
    border: OutlineInputBorder(),
    ),
    ),
    const SizedBox(height: 16),

    // 동화 생성 버튼
    ElevatedButton(
    onPressed: _generateStory,
    style: ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    backgroundColor: const Color(0xFFCF9595),
    ),
    child: const Text('동화 생성'),
    ),
    const SizedBox(height: 16),

    // 동화 내용 + 음성 재생 버튼
    if (_story.isNotEmpty) ...[
    Text(_story, style: const TextStyle(fontSize: 16)),
    Align(
    alignment: Alignment.centerRight,
    child: IconButton(
    onPressed: _readStory,
    icon: const Icon(Icons.volume_up),
    tooltip: '동화 읽기',
    ),
    ),
    ],
    const SizedBox(height: 16),

    // 이미지 설정: 컬러/색칠용
    const Text('이미지 스타일'),
    Row(
    children: [
    Expanded(
    child: RadioListTile(
    title: const Text('컬러'),
    value: '컬러',
    groupValue: _colorMode,
    onChanged: (value) =>
    setState(() => _colorMode = value!),
    ),
    ),
    Expanded(
    child: RadioListTile(
    title: const Text('색칠용'),
    value: '색칠용',
    groupValue: _colorMode,
    onChanged: (value) =>
    setState(() => _colorMode = value!),
    ),
    ),
    ],
    ),
    const SizedBox(height: 8),

    // 이미지 생성 버튼
    ElevatedButton(
    onPressed: _generateImage,
    style: ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    backgroundColor: Colors.teal,
    ),
    child: const Text('이미지 생성'),
    ),
    const SizedBox(height: 16),

    // 이미지 표시
    if (_imageUrl.isNotEmpty)
    Column(
    children: [
    Image.network(_imageUrl),
    const SizedBox(height: 8),

    // 공유 / 다운로드 버튼
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    ElevatedButton.icon(
    onPressed: _shareContent,
    icon: const Icon(Icons.share),
    label: const Text('공유'),
    ),
    ElevatedButton.icon(
    onPressed: _downloadImage,
    icon: const Icon(Icons.download),
    label: const Text('다운로드'),
    ),
    ],
    ),
    ],
    ),
    ],
    ),
    ),
    );
  }
}
