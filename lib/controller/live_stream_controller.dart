import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

class LiveStreamController {
  final String rtspUrl;
  final TextEditingController streamKeyController;
  final void Function(void Function()) onStateChange;
  final BuildContext context;
  final String platform; // Thêm thuộc tính để xác định nền tảng
  bool _isStreaming = false;

  LiveStreamController({
    required this.rtspUrl,
    required this.streamKeyController,
    required this.onStateChange,
    required this.context,
    required this.platform, // Thêm vào constructor
  });

  bool get isStreaming => _isStreaming;

  Future<void> startLiveStream() async {
    final streamKey = streamKeyController.text.trim();
    if (streamKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Stream Key')),
      );
      return;
    }

    if (_isStreaming) {
      await stopLiveStream();
    }

    onStateChange(() => _isStreaming = true);

    // Xác định RTMP URL dựa trên nền tảng
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

    final command =
        "-rtsp_transport tcp -fflags nobuffer -i $rtspUrl -c:v libx264 -preset veryfast -b:v 4000k -maxrate 4000k -bufsize 8000k -r 30 -c:a aac -b:a 128k -ar 44100 -ac 2 -g 25 -keyint_min 25 -tune zerolatency -f flv $rtmpUrl";

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