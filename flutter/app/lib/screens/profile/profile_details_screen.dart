// lib/profile_details_screen.dart
import 'package:flutter/material.dart';

import '../../main.dart';


class ProfileDetailsScreen extends StatefulWidget {
  @override
  _ProfileDetailsScreenState createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  // TODO: Spring Boot API에서 가져올 데이터 - 현재는 더미 데이터
  String _profileImagePath = 'assets/myphoto.png';
  final _nameController = TextEditingController(text: '동글이');
  final _emailController = TextEditingController(text: 'donggeul@example.com');
  final _phoneController = TextEditingController(text: '010-1234-5678');
  final _birthController = TextEditingController(text: '2024-03-15');

  @override
  void initState() {
    super.initState();
    // TODO: Spring Boot API에서 사용자 데이터 불러오기
    _loadUserData();
  }

  // TODO: Spring Boot API에서 사용자 데이터 불러오기
  Future<void> _loadUserData() async {
    // API 호출 예시:
    // final response = await http.get(Uri.parse('$baseUrl/api/user/profile'));
    // if (response.statusCode == 200) {
    //   final userData = json.decode(response.body);
    //   setState(() {
    //     _nameController.text = userData['name'] ?? '';
    //     _emailController.text = userData['email'] ?? '';
    //     _phoneController.text = userData['phone'] ?? '';
    //     _birthController.text = userData['birth'] ?? '';
    //     _profileImagePath = userData['profileImage'] ?? 'assets/myphoto.png';
    //   });
    // }
  }

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
                          border: Border.all(
                            color: Color(0xFFECA666),
                            width: 2.0, // 얇은 테두리
                          ),
                        ),
                        child: ClipOval(
                          child: Container(
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            child: Image.asset(
                              _profileImagePath,
                              fit: BoxFit.cover,
                              // TODO: 이미지 로드 실패 시 기본 이미지 표시
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Color(0xFFFDB5A6),
                                  child: Center(
                                    child: Text(
                                      '👶',
                                      style: TextStyle(fontSize: screenWidth * 0.08),
                                    ),
                                  ),
                                );
                              },
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
                            _showImagePickerDialog();
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
    // TODO: Spring Boot API로 프로필 저장
    // final userData = {
    //   'name': _nameController.text,
    //   'email': _emailController.text,
    //   'phone': _phoneController.text,
    //   'birth': _birthController.text,
    //   'profileImage': _profileImagePath,
    // };
    //
    // final response = await http.put(
    //   Uri.parse('$baseUrl/api/user/profile'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(userData),
    // );
    //
    // if (response.statusCode == 200) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('프로필이 저장되었습니다.'))
    //   );
    //   Navigator.pop(context);
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('저장에 실패했습니다.'))
    //   );
    // }

    // 현재는 더미 저장
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('프로필이 저장되었습니다.'),
        backgroundColor: Color(0xFF8E97FD),
      ),
    );
    Navigator.pop(context);
  }

  // TODO: 프로필 사진 변경 다이얼로그
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('프로필 사진 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

  // TODO: 카메라 촬영 기능
  void _pickImageFromCamera() {
    // image_picker 패키지와 Spring Boot API 연동
    // final picker = ImagePicker();
    // final pickedFile = await picker.pickImage(source: ImageSource.camera);
    // if (pickedFile != null) {
    //   await _uploadImage(File(pickedFile.path));
    // }
    print('카메라로 사진 촬영');
  }

  // TODO: 갤러리 선택 기능
  void _pickImageFromGallery() {
    // image_picker 패키지와 Spring Boot API 연동
    // final picker = ImagePicker();
    // final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   await _uploadImage(File(pickedFile.path));
    // }
    print('갤러리에서 사진 선택');
  }

// TODO: Spring Boot API로 이미지 업로드
// Future<void> _uploadImage(File imageFile) async {
//   final request = http.MultipartRequest(
//     'POST',
//     Uri.parse('$baseUrl/api/user/profile/image'),
//   );
//   request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
//
//   final response = await request.send();
//   if (response.statusCode == 200) {
//     final responseData = await response.stream.bytesToString();
//     final result = json.decode(responseData);
//     setState(() {
//       _profileImagePath = result['imageUrl'];
//     });
//   }
// }
}