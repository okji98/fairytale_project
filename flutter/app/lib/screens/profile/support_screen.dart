// lib/support_screen.dart
import 'package:flutter/material.dart';

import '../../main.dart';


class SupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 앱바
                Container(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                          'Support',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.06),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // 서포트 안내
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Color(0xFF8E97FD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: Color(0xFF8E97FD),
                        size: screenWidth * 0.08,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '도움이 필요하신가요?',
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '자주 묻는 질문을 확인하거나\n직접 문의를 남겨주세요.',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.black54,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // FAQ 섹션
                _buildSectionTitle(context, '자주 묻는 질문'),
                SizedBox(height: screenHeight * 0.02),

                _buildFAQItem(
                  context,
                  question: '동화는 어떻게 만들어지나요?',
                  answer: 'AI 기술을 활용하여 아이의 나이와 관심사에 맞는 개인화된 동화를 생성합니다. 부모님이 입력한 정보를 바탕으로 아이만의 특별한 이야기가 만들어집니다.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '색칠공부는 어떻게 이용하나요?',
                  answer: '동화에 등장하는 캐릭터와 장면들을 색칠할 수 있습니다. 완성된 작품은 갤러리에 저장되며, 가족과 공유할 수 있습니다.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '자장가 기능은 무엇인가요?',
                  answer: '아이가 편안히 잠들 수 있도록 도와주는 수면 음악과 자장가를 제공합니다. 타이머 기능으로 일정 시간 후 자동으로 종료됩니다.',
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildFAQItem(
                  context,
                  question: '기록일지는 어떤 기능인가요?',
                  answer: '아이와 함께한 동화 읽기 경험과 추억을 기록하고 공유할 수 있는 기능입니다. 사진과 함께 특별한 순간들을 저장하세요.',
                ),

                SizedBox(height: screenHeight * 0.04),

                // 빠른 도움말
                _buildSectionTitle(context, '빠른 도움말'),
                SizedBox(height: screenHeight * 0.02),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickHelpCard(
                        context,
                        icon: Icons.video_library,
                        title: '사용법 영상',
                        onTap: () {
                          // TODO: 사용법 영상 화면으로 이동
                          _showComingSoonDialog(context, '사용법 영상');
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: _buildQuickHelpCard(
                        context,
                        icon: Icons.quiz,
                        title: '튜토리얼',
                        onTap: () {
                          // TODO: 튜토리얼 화면으로 이동
                          _showComingSoonDialog(context, '튜토리얼');
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.04),

                // 문의하기
                _buildSectionTitle(context, '문의하기'),
                SizedBox(height: screenHeight * 0.02),

                _buildContactOption(
                  context,
                  icon: Icons.bug_report,
                  title: '버그 신고',
                  subtitle: '앱에서 발생한 문제를 신고해주세요',
                  onTap: () {
                    _showBugReportDialog(context);
                  },
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildContactOption(
                  context,
                  icon: Icons.lightbulb,
                  title: '기능 제안',
                  subtitle: '새로운 기능이나 개선사항을 제안해주세요',
                  onTap: () {
                    _showFeatureRequestDialog(context);
                  },
                ),

                SizedBox(height: screenHeight * 0.015),

                _buildContactOption(
                  context,
                  icon: Icons.star,
                  title: '리뷰 작성',
                  subtitle: '앱스토어에서 리뷰를 남겨주세요',
                  onTap: () {
                    // TODO: 앱스토어 리뷰 화면으로 이동
                    _showComingSoonDialog(context, '리뷰 작성');
                  },
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Text(
      title,
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B5A6B),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, {
    required String question,
    required String answer,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Color(0xFFF5E6A3).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.help,
                color: Color(0xFF8E97FD),
                size: screenWidth * 0.05,
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.07),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpCard(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Color(0xFF8E97FD).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF8E97FD).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Color(0xFF8E97FD),
              size: screenWidth * 0.08,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Color(0xFFF5E6A3).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                icon,
                color: Color(0xFF8B5A6B),
                size: screenWidth * 0.05,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black38,
              size: screenWidth * 0.04,
            ),
          ],
        ),
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('버그 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('발생한 문제를 자세히 설명해주세요.'),
              SizedBox(height: 16),
              TextField(
                controller: reportController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '문제 상황을 입력해주세요...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 실제 버그 신고 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('버그 신고가 접수되었습니다.'),
                    backgroundColor: Color(0xFF8E97FD),
                  ),
                );
              },
              child: Text('신고하기'),
            ),
          ],
        );
      },
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    final TextEditingController requestController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('기능 제안'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('원하시는 기능이나 개선사항을 알려주세요.'),
              SizedBox(height: 16),
              TextField(
                controller: requestController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '제안하고 싶은 기능을 입력해주세요...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 실제 기능 제안 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('소중한 제안 감사합니다!'),
                    backgroundColor: Color(0xFF8E97FD),
                  ),
                );
              },
              child: Text('제안하기'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('준비중'),
          content: Text('$feature 기능을 준비 중입니다.\n곧 만나보실 수 있어요!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }
}