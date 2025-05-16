// D:\AndroidStudioProjects\vnvar_flutter\lib\main.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
// Khởi tạo đúng platform dựa trên thiết bị
  late final PlatformWebViewControllerCreationParams params;
  if (WebViewPlatform.instance != null) {
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    } else {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

  }  runApp(const MyApp());
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
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}