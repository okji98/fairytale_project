// lib/profile_details_screen.dart
import 'package:flutter/material.dart';
import 'main.dart';

class ProfileDetailsScreen extends StatefulWidget {
  @override
  _ProfileDetailsScreenState createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _nameController = TextEditingController(text: '동글이');
  final _emailController = TextEditingController(text: 'donggeul@example.com');
  final _phoneController = TextEditingController(text: '010-1234-5678');
  final _birthController = TextEditingController(text: '2024-03-15');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    super.dispose();
  }

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
                          'Profile Details',
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

                SizedBox(height: screenHeight * 0.03),

                // 프로필 이미지
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: screenWidth * 0.25,
                        height: screenWidth * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF9C7CB8),
                              Color(0xFFB8A5D1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: screenWidth * 0.16,
                            height: screenWidth * 0.16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFDB5A6),
                            ),
                            child: Center(
                              child: Text(
                                '👶',
                                style: TextStyle(fontSize: screenWidth * 0.08),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: 프로필 사진 변경 기능
                          },
                          child: Container(
                            width: screenWidth * 0.07,
                            height: screenWidth * 0.07,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF8B5A6B),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // 입력 필드들
                _buildInputField(
                  context,
                  label: '이름',
                  controller: _nameController,
                  icon: Icons.person,
                ),

                SizedBox(height: screenHeight * 0.02),

                _buildInputField(
                  context,
                  label: '이메일',
                  controller: _emailController,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: screenHeight * 0.02),

                _buildInputField(
                  context,
                  label: '전화번호',
                  controller: _phoneController,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: screenHeight * 0.02),

                _buildInputField(
                  context,
                  label: '생년월일',
                  controller: _birthController,
                  icon: Icons.cake,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),

                SizedBox(height: screenHeight * 0.05),

                // 저장 버튼
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8E97FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    ),
                    child: Text(
                      '저장하기',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required IconData icon,
        TextInputType? keyboardType,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF5E6A3).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: Color(0xFF8B5A6B),
                size: screenWidth * 0.05,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2024, 3, 15),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8E97FD),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveProfile() {
    // TODO: 실제 프로필 저장 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('프로필이 저장되었습니다.'),
        backgroundColor: Color(0xFF8E97FD),
      ),
    );
    Navigator.pop(context);
  }
}