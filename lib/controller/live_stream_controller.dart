// D:\AndroidStudioProjects\vnvar_flutter\lib\controller\live_stream_controller.dart
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveStreamController {
  String? _rtspUrl;
  final TextEditingController streamKeyController;
  final void Function(void Function()) onStateChange;
  final BuildContext context;
  final String platform;
  final String? liveStreamTitle;
  final String? accessToken; // Chỉ nhận từ FacebookPlatform
  bool _isStreaming = false;

  LiveStreamController({
    required this.streamKeyController,
    required this.onStateChange,
    required this.context,
    required this.platform,
    this.liveStreamTitle,
    this.accessToken,
  }) {
    _loadRtspUrl();
  }

  Future<void> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _rtspUrl = prefs.getString('rtspUrl');
  }

  bool get isStreaming => _isStreaming;

  Future<String?> _createFacebookLiveStream() async {
    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập Facebook để lấy Access Token')),
      );
      return null;
    }

    try {
      final url = Uri.parse('https://graph.facebook.com/v19.0/me/live_videos');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'LIVE_NOW',
          'title': liveStreamTitle ?? 'Live Stream from Flutter RTSP',
          'description': liveStreamTitle ?? '',
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
    final streamKey = streamKeyController.text.trim();

    if (platform == 'YouTube') {
      if (streamKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập Stream Key cho YouTube')),
        );
        return;
      }
      rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
    } else if (platform == 'Facebook') {
      if(accessToken==null) {
        rtmpUrl = "rtmps://live-api-s.facebook.com:443/rtmp/$streamKey";

        print("access token không tồn tại");
      } else {
        print('Stream Key từ LiveStreamScreen (Facebook): $streamKey');
        print('accessToken từ LiveStreamScreen (Facebook): $accessToken');
        // Chỉ sử dụng accessToken từ FacebookPlatform để tạo stream
        rtmpUrl = await _createFacebookLiveStream();
      }
      if (rtmpUrl == null) {
        return; // Thoát nếu không tạo được rtmpUrl
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nền tảng không được hỗ trợ')),
      );
      return;
    }

    print('RTMP URL: $rtmpUrl');
    print('liveStreamTitle: $liveStreamTitle');
    print('accessToken: $accessToken');

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