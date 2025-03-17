// D:\AndroidStudioProjects\vnvar_flutter\lib\utils\ffmpeg_yt.dart
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FFmpegYT {
  FFmpegSession? _session;
  String? _rtspUrl;

  FFmpegYT() {
    _loadRtspUrl(); // Gọi hàm load trong constructor
  }

  // Tải RTSP URL từ SharedPreferences
  Future<void> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _rtspUrl = prefs.getString('rtspUrl');
  }

  Future<void> startStreaming(String streamKey, {required Function(String) onError}) async {
    // Đảm bảo RTSP URL đã được tải
    await _loadRtspUrl();

    if (_rtspUrl == null || _rtspUrl!.isEmpty) {
      onError('Không tìm thấy RTSP URL trong SharedPreferences');
      return;
    }

    final ffmpegCommand =
        '-rtsp_transport tcp -fflags nobuffer -i "$_rtspUrl" '
        '-c:v libx264 -preset ultrafast -b:v 2000k -maxrate 2500k -bufsize 5000k -r 30 '
        '-c:a aac -b:a 96k -ar 44100 -ac 2 -g 60 -keyint_min 60 -tune zerolatency '
        '-f flv "rtmp://a.rtmp.youtube.com/live2/$streamKey"';

    _session = await FFmpegKit.executeAsync(
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
  }

  Future<void> cancelSession() async {
    if (_session != null) {
      await _session!.cancel();
      _session = null;
    }
  }
}