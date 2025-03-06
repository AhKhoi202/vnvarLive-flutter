import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveStreamController {
  String? _rtspUrl;
  final TextEditingController streamKeyController;
  final void Function(void Function()) onStateChange;
  final BuildContext context;
  final String platform;
  final String? liveStreamTitle;
  bool _isStreaming = false;
  String? _accessToken;

  LiveStreamController({
    required this.streamKeyController,
    required this.onStateChange,
    required this.context,
    required this.platform,
    this.liveStreamTitle,
  }) {
    _loadRtspUrl();
    _checkFacebookLogin();
  }

  Future<void> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _rtspUrl = prefs.getString('rtspUrl');
  }

  Future<void> _checkFacebookLogin() async {
    final accessToken = await FacebookAuth.instance.accessToken;
    if (accessToken != null) {
      _accessToken = accessToken.tokenString;
    }
  }

  bool get isStreaming => _isStreaming;

  // Hàm yêu cầu đăng nhập nếu chưa có token
  Future<bool> _ensureFacebookLogin() async {
    if (_accessToken == null) {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'publish_video'],
      );
      if (result.status == LoginStatus.success) {
        _accessToken = result.accessToken!.tokenString;
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại: ${result.message}')),
        );
        return false;
      }
    }
    return true;
  }

  Future<String?> _createFacebookLiveStream() async {
    if (!await _ensureFacebookLogin()) {
      return null; // Thoát nếu đăng nhập thất bại
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
          'title': liveStreamTitle ?? 'Live Stream from Flutter RTSP',
          'description': liveStreamTitle,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stream_url'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo livestream thất bại: ${response.body}')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo livestream: $e')),
      );
      return null;
    }
  }

  Future<void> startLiveStream() async {
    if (_rtspUrl == null || _rtspUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy RTSP URL')),
      );
      return;
    }

    if (_isStreaming) {
      await stopLiveStream();
    }

    String? rtmpUrl;

    if (platform == 'YouTube') {
      final streamKey = streamKeyController.text.trim();
      if (streamKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập Stream Key cho YouTube')),
        );
        return;
      }
      rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
    } else if (platform == 'Facebook') {
      rtmpUrl = await _createFacebookLiveStream();
      if (rtmpUrl == null) {
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nền tảng không được hỗ trợ')),
      );
      return;
    }

    print('RTMP URL: $rtmpUrl');
    print('liveStreamTitle: $liveStreamTitle');
    print('_accessToken: $_accessToken');

    final command =
        "-rtsp_transport tcp -fflags nobuffer -i \"$_rtspUrl\" -c:v libx264 -preset veryfast -b:v 4000k -maxrate 4000k -bufsize 8000k -r 30 -c:a aac -b:a 128k -ar 44100 -ac 2 -g 25 -keyint_min 25 -tune zerolatency -f flv \"$rtmpUrl\"";

    try {
      onStateChange(() => _isStreaming = true);
      FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Livestream bắt đầu thành công')),
            );
          }
        } else {
          if (context.mounted) {
            onStateChange(() => _isStreaming = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Livestream thất bại: ${await session.getFailStackTrace()}')),
            );
          }
        }
      });
    } catch (e) {
      onStateChange(() => _isStreaming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi bắt đầu livestream: $e')),
      );
    }
  }

  Future<void> stopLiveStream() async {
    if (_isStreaming) {
      FFmpegKit.cancel();
      onStateChange(() => _isStreaming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livestream đã dừng thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có livestream đang chạy để dừng')),
      );
    }
  }
}