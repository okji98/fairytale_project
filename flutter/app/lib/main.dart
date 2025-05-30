// lib/main.dart
import 'package:app/stories_screen.dart';
import 'package:flutter/material.dart';

import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'child_info_screen.dart';
import 'home_screen.dart';

// Ensure assets are declared in pubspec.yaml:
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
      ),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/childInfo': (context) => ChildInfoScreen(),
        '/home': (context) => HomeScreen(),
        '/stories':    (ctx) => StoriesScreen(),
      },
    );
  }
}
