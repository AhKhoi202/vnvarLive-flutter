// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\facebook_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:http/http.dart' as http;
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'dart:convert';

class FacebookLoginScreen extends StatefulWidget {
  const FacebookLoginScreen({Key? key}) : super(key: key);

  @override
  _FacebookLoginScreenState createState() => _FacebookLoginScreenState();
}

class _FacebookLoginScreenState extends State<FacebookLoginScreen> {
  String? _accessToken;
  bool _isLoggedIn = false;
  String? _streamUrl;
  FFmpegSession? _ffmpegSession;

  // Hàm đăng nhập
  Future<void> _login() async {
    try {
      print('Starting Facebook login...');
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'publish_video'],
      );
      print('Login status: ${result.status}');
      print('Login message: ${result.message}');
      if (result.status == LoginStatus.success) {
        _accessToken = result.accessToken!.tokenString;
        setState(() {
          _isLoggedIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thành công: $_accessToken')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại: ${result.message}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // Hàm đăng xuất
  Future<void> _logout() async {
    await _stopLiveStream(); // Dừng livestream trước khi đăng xuất
    await FacebookAuth.instance.logOut();
    setState(() {
      _accessToken = null;
      _isLoggedIn = false;
      _streamUrl = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đăng xuất')),
    );
  }

  // Hàm tạo livestream trên Facebook
  Future<void> _createLiveStream() async {
    if (_accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước')),
      );
      return;
    }

    try {
      final url = Uri.parse('https://graph.facebook.com/v19.0/me/live_videos');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'LIVE_NOW',
          'title': 'Live Stream from Flutter RTSP',
          'description': 'Streaming from RTSP source',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _streamUrl = data['stream_url'];
        });
        print('Stream URL: $_streamUrl');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo livestream thành công: $_streamUrl')),
        );
      } else {
        print('Response: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo livestream thất bại: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error creating livestream: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // Hàm bắt đầu livestream từ RTSP bằng FFmpeg
  Future<void> _startLiveStream() async {
    if (_streamUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo livestream trước')),
      );
      return;
    }

    if (_ffmpegSession != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livestream đang chạy, vui lòng dừng trước')),
      );
      return;
    }

    const rtspUrl = 'rtsp://admin:VNDC121212@192.168.1.8:554/Streaming/Channels/1';
    final command =
        "-rtsp_transport tcp -fflags nobuffer -i \"$rtspUrl\" -c:v libx264 -preset veryfast -b:v 4000k -maxrate 4000k -bufsize 8000k -r 30 -c:a aac -b:a 128k -ar 44100 -ac 2 -g 25 -keyint_min 25 -tune zerolatency -f flv \"$_streamUrl\"";

    try {
      print('FFmpeg command: $command');
      _ffmpegSession = await FFmpegKit.executeAsync(
        command,
            (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            print('Streaming started successfully');
          } else {
            final failLog = await session.getFailStackTrace();
            print('Streaming failed: $failLog');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Streaming thất bại: $failLog')),
              );
            }
          }
          setState(() {
            _ffmpegSession = null; // Reset session sau khi hoàn tất hoặc lỗi
          });
        },
            (log) => print(log.getMessage()), // In log FFmpeg
        null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu livestream')),
      );
    } catch (e) {
      print('Error starting livestream: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      setState(() {
        _ffmpegSession = null;
      });
    }
  }

  // Hàm dừng livestream
  Future<void> _stopLiveStream() async {
    if (_ffmpegSession != null) {
      await _ffmpegSession!.cancel();
      setState(() {
        _ffmpegSession = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã dừng livestream')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có livestream đang chạy')),
      );
    }
  }

  @override
  void dispose() {
    _stopLiveStream(); // Dừng livestream khi widget bị hủy
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facebook Login & Livestream')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isLoggedIn)
              ElevatedButton(
                onPressed: _login,
                child: const Text('Đăng nhập bằng Facebook'),
              )
            else ...[
              const Text('Đã đăng nhập!'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createLiveStream,
                child: const Text('Tạo Livestream'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startLiveStream,
                child: const Text('Bắt đầu Livestream từ RTSP'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _stopLiveStream,
                child: const Text('Dừng Livestream'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Đăng xuất'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}