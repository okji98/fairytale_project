// lib/main.dart
import 'package:app/profile_details_screen.dart';
import 'package:app/profile_screen.dart';
import 'package:app/settings_screen.dart';
import 'package:app/stories_screen.dart';
import 'package:app/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 추가

import 'coloring_screen.dart';
import 'contacts_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'child_info_screen.dart';
import 'home_screen.dart';

// pubspec.yaml에 추가할 것들:
// dependencies:
//   google_fonts: ^6.1.0
//
// flutter:
//   assets:
//     - assets/bg_image.png
//     - assets/bg_login.png
//     - assets/bear.png
//     - assets/book_bear.png
//     - assets/kakao_icon.png
//     - assets/google_icon.png
//     - assets/stories_icon.png
//     - assets/coloring_icon.png
//     - assets/share_icon.png
//     - assets/lullabies_icon.png
//     - assets/myphoto.png
//     - assets/logo.png
//     - assets/rabbit.png
//     - assets/profile_icon.png
//     - assets/love.png
//     - assets/cloud.png
//     - assets/coloring_bear.png

void main() {
  runApp(MyApp());
}

/// A scaffold that applies a default background image to all screens,
/// with optional override per screen.
class BaseScaffold extends StatelessWidget {
  final Widget child;
  final Widget? background;

  const BaseScaffold({
    required this.child,
    this.background,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // background 파라미터가 있으면 Stack으로 덮어주고,
        // 없으면 bg_image.png를 BoxDecoration으로 그립니다.
        decoration: background == null
            ? BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_image.png'),
            fit: BoxFit.cover,
          ),
        )
            : null,
        child: background != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            background!,
            child,
          ],
        )
            : child,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1조 Project',
      theme: ThemeData(
        primarySwatch: Colors.blue,

        // Hi Melody 폰트를 앱 전체 기본 폰트로 설정 (적정 사이즈로 조정)
        textTheme: GoogleFonts.hiMelodyTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          // 개별 텍스트 스타일 커스터마이징 (오버플로우 방지를 위해 약간 조정)
          headlineLarge: GoogleFonts.hiMelody(
            fontSize: 36, // 40 → 36
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          headlineMedium: GoogleFonts.hiMelody(
            fontSize: 32, // 36 → 32
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          headlineSmall: GoogleFonts.hiMelody(
            fontSize: 28, // 30 → 28
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleLarge: GoogleFonts.hiMelody(
            fontSize: 24, // 26 → 24
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleMedium: GoogleFonts.hiMelody(
            fontSize: 20, // 22 → 20
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          titleSmall: GoogleFonts.hiMelody(
            fontSize: 18, // 20 → 18
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodyLarge: GoogleFonts.hiMelody(
            fontSize: 18, // 20 → 18
            color: Colors.black87,
          ),
          bodyMedium: GoogleFonts.hiMelody(
            fontSize: 16, // 18 → 16
            color: Colors.black87,
          ),
          bodySmall: GoogleFonts.hiMelody(
            fontSize: 14, // 16 → 14
            color: Colors.black54,
          ),
          labelLarge: GoogleFonts.hiMelody(
            fontSize: 16, // 18 → 16
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          labelMedium: GoogleFonts.hiMelody(
            fontSize: 14, // 16 → 14
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          labelSmall: GoogleFonts.hiMelody(
            fontSize: 12, // 14 → 12
            color: Colors.black54,
          ),
        ),

        // 앱바 테마
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.hiMelody(
            fontSize: 22, // 24 → 22
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        // ElevatedButton 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.hiMelody(
              fontSize: 18, // 20 → 18
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // TextButton 테마
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: GoogleFonts.hiMelody(
              fontSize: 16, // 18 → 16
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // InputDecoration 테마 (TextField 등)
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.hiMelody(
            fontSize: 16, // 18 → 16
            color: Colors.black54,
          ),
          hintStyle: GoogleFonts.hiMelody(
            fontSize: 16, // 18 → 16
            color: Colors.black38,
          ),
        ),
      ),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/childInfo': (context) => ChildInfoScreen(),
        '/home': (context) => HomeScreen(),
        '/stories': (ctx) => StoriesScreen(),
        '/profile': (context) => ProfileScreen(),
        '/profile-details': (context) => ProfileDetailsScreen(),
        '/settings': (context) => SettingsScreen(),
        '/contacts': (context) => ContactsScreen(),
        '/support': (context) => SupportScreen(),
        // TODO: 추가 필요한 라우트들
        '/coloring': (context) => ColoringScreen(),
        '/share': (context) => Container(),    // ShareScreen(),
        '/lullabies': (context) => Container(), // LullabiesScreen(),
      },
    );
  }
}