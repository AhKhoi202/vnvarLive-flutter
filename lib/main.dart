// D:\AndroidStudioProjects\vnvar_flutter\lib\main.dart
import 'package:flutter/material.dart';
import 'package:vnvar_flutter/widgets/scoreboard_input_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VNVAR App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: const YouTubeStreamScreen(),
      home: const HomeScreen(),
      // home: InputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}