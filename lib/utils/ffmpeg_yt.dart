// D:\AndroidStudioProjects\vnvar_flutter\lib\utils\ffmpeg_yt.dart
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FFmpegYT {
  FFmpegSession? _session;
  String? _rtspUrl;
  bool _isScoreboardVisible;

  FFmpegYT({bool isScoreboardVisible = false}) : _isScoreboardVisible = isScoreboardVisible {
    _loadRtspUrl();
  }

  // Tải RTSP URL từ SharedPreferences
  Future<void> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _rtspUrl = prefs.getString('rtspUrl');
  }

  Future<void> startStreaming(String streamKey, {required Function(String) onError}) async {
    await _loadRtspUrl();

    if (_rtspUrl == null || _rtspUrl!.isEmpty) {
      onError('Không tìm thấy RTSP URL trong SharedPreferences');
      return;
    }

    final directory = await getTemporaryDirectory();
    final scoreboardPath = '${directory.path}/scoreboard.png';

    // Xây dựng lệnh FFmpeg
    List<String> args = [
      '-loglevel',
      'info',
      '-rtsp_transport',
      'tcp',
      '-fflags',
      'nobuffer',
      '-re', // Đọc input ở tốc độ thực
      '-i',
      _rtspUrl!,
    ];

    print('_isScoreboardVisible: $_isScoreboardVisible'); // In RTSP URL để kiểm tra

    // Thêm overlay nếu bảng tỷ số được bật
    if (_isScoreboardVisible && await File(scoreboardPath).exists()) {
      args.addAll([
        '-stream_loop', // Lặp lại hình ảnh overlay
        '-1',           // Lặp vô hạn
        '-f',
        'image2',       // Định dạng input là ảnh tĩnh
        '-re',          // Đọc ở tốc độ thực
        '-i',
        scoreboardPath,
        '-filter_complex',
        '[1:v]scale=iw*0.5:-1[overlay];[0:v][overlay]overlay=main_w*0.05:main_h*0.05', // Căn trái trên
        // '[1:v]scale=iw*0.8:-1[overlay];[0:v][overlay]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)-100', // Căn giữa, cách dưới 100px
      ]);
    }

    // Thêm các tùy chọn mã hóa và output
    args.addAll([
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-b:v',
      '2000k',
      '-maxrate',
      '2500k',
      '-bufsize',
      '5000k',
      '-r',
      '30',
      '-g',
      '60',
      '-c:a',
      'aac',
      '-b:a',
      '96k',
      '-ar',
      '44100',
      '-ac',
      '2',
      '-tune',
      'zerolatency',
      '-f',
      'flv',
      '-rtmp_buffer',
      '3000',
      '-rtmp_live',
      'live',
      'rtmp://a.rtmp.youtube.com/live2/$streamKey',
    ]);

    // Chuyển List<String> thành chuỗi lệnh
    final ffmpegCommand = args.join(' ');
    print('FFmpeg command: $ffmpegCommand'); // In lệnh để kiểm tra

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

  void updateScoreboardVisibility(bool isVisible) {
    _isScoreboardVisible = isVisible;
  }

  // Thêm vào lớp FFmpegYT
  bool isStreaming() {
    return _session != null;
  }
}
