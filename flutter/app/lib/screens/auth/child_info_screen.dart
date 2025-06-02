// lib/screens/auth/child_info_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../main.dart';

class ChildInfoScreen extends StatefulWidget {
  @override
  _ChildInfoScreenState createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends State<ChildInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1), // 출산 예정일도 고려
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ✅ 아이 정보를 서버에 저장
  Future<bool> _saveChildInfo() async {
    if (_nameController.text.trim().isEmpty || _selectedDate == null) {
      _showErrorDialog('아이의 이름과 생일을 모두 입력해주세요.');
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();

      final response = await dio.post(
        'http://10.0.2.2:8080/api/baby',
        data: {
          'name': _nameController.text.trim(),
          'birthDate': '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            // TODO: 로그인 후 받은 JWT 토큰을 여기에 추가
            // 'Authorization': 'Bearer ${저장된_JWT_토큰}',
          },
        ),
      );

      print('아이 정보 저장 응답: ${response.data}');

      if (response.data['success'] == true) {
        print('아이 정보 저장 성공!');
        return true;
      }
      return false;
    } catch (e) {
      print('아이 정보 저장 오류: $e');
      _showErrorDialog('아이 정보 저장에 실패했습니다. 다시 시도해주세요.');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기 버튼 추가
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.brown),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '아이 정보 입력',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 균형 맞추기
                ],
              ),
              const SizedBox(height: 32),

              Text(
                'Child Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '아이의 이름(태명)을 입력해 주세요',
                  fillColor: Color(0xFFFFE7B0),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 24),

              Text(
                'Birth Day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE7B0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                        : '아이의 생일(출산 예정일)을 입력해 주세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null ? Color(0xFF3B2D2C) : Colors.grey[600],
                    ),
                  ),
                ),
              ),

              Spacer(),

              // 저장 버튼
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  final success = await _saveChildInfo();
                  if (success) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF6B756),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text('SAVE'),
              ),

              SizedBox(height: 8),

              // 건너뛰기 버튼
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text(
                  'NO THANKS',
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}