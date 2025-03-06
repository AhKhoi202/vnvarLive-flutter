import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm import này

class LiveStreamController {
  String? _rtspUrl; // Không cần truyền qua constructor nữa
  final TextEditingController streamKeyController;
  final void Function(void Function()) onStateChange;
  final BuildContext context;
  final String platform;
  bool _isStreaming = false;

  LiveStreamController({
    required this.streamKeyController,
    required this.onStateChange,
    required this.context,
    required this.platform,
  }) {
    _loadRtspUrl(); // Tự động lấy rtspUrl khi khởi tạo
  }

  // Hàm lấy RTSP URL từ SharedPreferences
  Future<void> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _rtspUrl = prefs.getString('rtspUrl');
  }

  bool get isStreaming => _isStreaming;

  Future<void> startLiveStream() async {
    final streamKey = streamKeyController.text.trim();
    if (streamKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Stream Key')),
      );
      return;
    }
    if (_rtspUrl == null || _rtspUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy RTSP URL')),
      );
      return;
    }

    if (_isStreaming) {
      await stopLiveStream();
    }

    onStateChange(() => _isStreaming = true);

    String rtmpUrl;
    if (platform == 'YouTube') {
      rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
    } else if (platform == 'Facebook') {
      rtmpUrl = "rtmps://live-api-s.facebook.com:443/rtmp/$streamKey";
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nền tảng không được hỗ trợ')),
      );
      return;
    }
    print(rtmpUrl);

    final command =
        "-rtsp_transport tcp -fflags nobuffer -i $_rtspUrl -c:v libx264 -preset veryfast -b:v 4000k -maxrate 4000k -bufsize 8000k -r 30 -c:a aac -b:a 128k -ar 44100 -ac 2 -g 25 -keyint_min 25 -tune zerolatency -f flv $rtmpUrl";

    FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Streaming started successfully')),
          );
        }
      } else {
        if (context.mounted) {
          onStateChange(() => _isStreaming = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Streaming failed: ${await session.getFailStackTrace()}')),
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Streaming started successfully')),
    );
  }

  Future<void> stopLiveStream() async {
    if (_isStreaming) {
      FFmpegKit.cancel();
      onStateChange(() => _isStreaming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livestream stopped successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active livestream to stop')),
      );
    }
  }
}