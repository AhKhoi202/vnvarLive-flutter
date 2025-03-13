import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

class FFmpegHelper {
  FFmpegSession? _session;

  Future<void> startStreaming(String streamKey, {required Function(String) onError}) async {
    final ffmpegCommand =
        '-rtsp_transport tcp -fflags nobuffer -i "rtsp://admin:VNDC121212@192.168.1.10/cam/realmonitor?channel=1&subtype=0" '
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