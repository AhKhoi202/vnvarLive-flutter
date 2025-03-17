import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class YouTubeStreamer {
  final TextEditingController streamKeyController;
  final BuildContext context;

  YouTubeStreamer({
    required this.streamKeyController,
    required this.context,
  });

  Future<String?> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rtspUrl');
  }

  Future<void> startStreaming({required Function(String) onError}) async {
    final rtspUrl = await _loadRtspUrl();
    if (rtspUrl == null || rtspUrl.isEmpty) {
      onError('Không tìm thấy RTSP URL trong SharedPreferences');
      return;
    }

    final streamKey = streamKeyController.text.trim();
    if (streamKey.isEmpty) {
      onError('Vui lòng nhập Stream Key cho YouTube');
      return;
    }

    final rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey";
    final ffmpegCommand =
        '-rtsp_transport tcp -fflags nobuffer -i "$rtspUrl" '
        '-c:v libx264 -preset ultrafast -b:v 2000k -maxrate 2500k -bufsize 5000k -r 30 '
        '-c:a aac -b:a 96k -ar 44100 -ac 2 -g 60 -keyint_min 60 -tune zerolatency '
        '-f flv "$rtmpUrl"';

    try {
      await FFmpegKit.executeAsync(
        ffmpegCommand,
            (session) async {
          final returnCode = await session.getReturnCode();
          if (!ReturnCode.isSuccess(returnCode) && !ReturnCode.isCancel(returnCode)) {
            final logs = await session.getAllLogsAsString();
            onError(logs ?? 'Unknown FFmpeg error');
          }
        },
            (log) => print('FFmpeg log: ${log.getMessage()}'),
      );
    } catch (e) {
      onError('Lỗi khi bắt đầu livestream: $e');
    }
  }

  Future<void> stopStreaming() async {
    await FFmpegKit.cancel();
  }
}