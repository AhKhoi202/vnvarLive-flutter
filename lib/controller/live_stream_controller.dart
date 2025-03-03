//D:\AndroidStudioProjects\vnvar_flutter\lib\controller\live_stream_controller.dart
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

class LiveStreamController {
  final String rtspUrl;
  final TextEditingController streamKeyController;
  final void Function(void Function()) onStateChange;
  final BuildContext context;
  bool _isStreaming = false;

  LiveStreamController({
    required this.rtspUrl,
    required this.streamKeyController,
    required this.onStateChange,
    required this.context,
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

    final rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
    final command =
        "-rtsp_transport tcp -analyzeduration 10000000 -probesize 5000000 -i $rtspUrl -c:v libx264 -preset veryfast -c:a aac -b:a 128k -f flv $rtmpUrl";

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