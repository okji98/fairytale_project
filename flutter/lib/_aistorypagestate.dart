import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'aistorypage.dart';


class _AIStoryPageState extends State<AIStoryPage> {
  final _keywordController = TextEditingController();
  final _lengthController  = TextEditingController();
  String _story = '';

  @override
  void dispose() {
    _keywordController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _generateStory() {
    final keywords = _keywordController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // TODO: keywords 리스트와 length를 API로 전송
    setState(() {
      _story = '키워드 → ${keywords.join(' • ')}\n'
          '분량 → 약 ${_lengthController.text}자\n\n'
          '…생성된 동화가 여기에 출력됩니다.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 쉼표로 구분된 키워드 입력란
          TextField(
            controller: _keywordController,
            decoration: const InputDecoration(
              labelText: '키워드 입력 (쉼표로 구분)',
              hintText: '예) 용감한 왕자, 마법의 숲, 작은 거인',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 글 길이 입력란
          TextField(
            controller: _lengthController,
            decoration: const InputDecoration(
              labelText: '글 길이(자) 입력',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // 동화 생성 버튼
          ElevatedButton(
            onPressed: _generateStory,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFFECA666),
            ),
            child: const Text('동화 생성'),
          ),
          const SizedBox(height: 16),

          // 생성된 동화 텍스트
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _story,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),

          // 읽어주기 버튼
          if (_story.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  // TODO: TTS 로직
                },
                icon: const Icon(Icons.volume_up),
                tooltip: '동화 읽어주기',
              ),
            ),
        ],
      ),
    );
  }
}
