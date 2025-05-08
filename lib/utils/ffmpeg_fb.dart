// D:\AndroidStudioProjects\vnvar_flutter\lib\utils\ffmpeg_fb.dart
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FFmpegFB {
  FFmpegSession? _session;
  String? _rtspUrl;
  static const String _facebookApiUrl = 'https://graph.facebook.com/v19.0/me/live_videos';
  final Function()? _onStateChanged;
  bool _isScoreboardVisible; // Biến trạng thái bảng tỷ số

  final bool Function()? _getScoreboardVisibility; // Hàm callback để lấy trạng thái bảng tỷ số

  FFmpegFB({
    Function()? onStateChanged,
    bool isScoreboardVisible = false,
    bool Function()? getScoreboardVisibility, // Callback mới
  })  : _onStateChanged = onStateChanged,
        _isScoreboardVisible = isScoreboardVisible,
        _getScoreboardVisibility = getScoreboardVisibility {
    _loadRtspUrl();
  }

  // Tải RTSP URL từ SharedPreferences
  Future<void> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _rtspUrl = prefs.getString('rtspUrl');
  }

  // Tạo livestream trên Facebook và lấy RTMP URL (dùng accessToken)
  Future<String?> _createFacebookLiveStream({
    required String accessToken,
    String? title,
    required Function(String) onError,
  }) async {
    try {
      final url = Uri.parse(_facebookApiUrl);
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'LIVE_NOW',
          'title': title ?? 'Live Stream from Flutter RTSP',
          'description': title ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stream_url'];
      } else {
        onError('Lỗi tạo livestream qua API: ${response.body}');
        return null;
      }
    } catch (e) {
      onError('Lỗi khi tạo livestream qua API: $e');
      return null;
    }
  }

  // Bắt đầu streaming lên Facebook
  Future<void> startStreaming({
    required String streamKey,
    String? accessToken,
    String? title,
    required Function(String) onError,
  }) async {
    // Lấy giá trị mới nhất nếu có callback
    if (_getScoreboardVisibility != null) {
      _isScoreboardVisible = _getScoreboardVisibility!();
    }
    // In giá trị để kiểm tra
    print('FB_isScoreboardVisible (cập nhật mới): $_isScoreboardVisible');
    await _loadRtspUrl();
    if (_rtspUrl == null || _rtspUrl!.isEmpty) {
      onError('Không tìm thấy RTSP URL trong SharedPreferences');
      return;
    }

    String? rtmpUrl;

    // Trường hợp dùng accessToken
    if (accessToken != null && accessToken.isNotEmpty) {
      rtmpUrl = await _createFacebookLiveStream(
        accessToken: accessToken,
        title: title,
        onError: onError,
      );
    }
    // Trường hợp dùng streamKey
    else if (streamKey.isNotEmpty) {
      rtmpUrl = "rtmps://live-api-s.facebook.com:443/rtmp/$streamKey";
    } else {
      onError('Cần ít nhất Stream Key hoặc Access Token để livestream');
      return;
    }

    if (rtmpUrl == null) {
      return;
    }

    print('RTMP URL: $rtmpUrl');
    print('Title: $title');
    print('Access Token: $accessToken');
    print('Stream Key: $streamKey');

    final directory = await getTemporaryDirectory();
    final scoreboardPath = '${directory.path}/scoreboard.png';

    // Xây dựng lệnh FFmpeg
    List<String> ffmpegCommand = [
      '-rtsp_transport', 'tcp',
      '-fflags', 'nobuffer',
      '-re', // Đọc input ở tốc độ thực
      '-i', '"$_rtspUrl"',
    ];
    print('FB_isScoreboardVisible: $_isScoreboardVisible'); // In RTSP URL để kiểm tra

    // Thêm overlay nếu bảng tỷ số được bật
    if (_isScoreboardVisible && await File(scoreboardPath).exists()) {
      ffmpegCommand.addAll([
        '-stream_loop', '-1', // Lặp vô hạn hình ảnh overlay
        '-f', 'image2', // Định dạng input là ảnh tĩnh
        '-re', // Đọc ở tốc độ thực
        '-i', scoreboardPath,
        '-filter_complex',
        '[1:v]scale=iw*0.5:-1[overlay];[0:v][overlay]overlay=main_w*0.05:main_h*0.05', // Căn trái trên
        // '[1:v]scale=iw*0.8:-1[overlay];[0:v][overlay]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)-100', // Căn giữa, cách dưới 100px
      ]);
    }

    // Thêm các tùy chọn mã hóa và output
    ffmpegCommand.addAll([
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-b:v', '2500k',
      '-maxrate', '3000k',
      '-bufsize', '6000k',
      '-r', '30',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-ar', '44100',
      '-ac', '2',
      '-g', '60',
      '-keyint_min', '60',
      '-tune', 'zerolatency',
      '-f', 'flv',
      '"$rtmpUrl"',
    ]);

    final commandString = ffmpegCommand.join(' ');
    print('FFmpeg command: $commandString'); // In lệnh để kiểm tra

    _session = await FFmpegKit.executeAsync(
      commandString,
          (session) async {
        final returnCode = await session.getReturnCode();
        if (!ReturnCode.isSuccess(returnCode) && !ReturnCode.isCancel(returnCode)) {
          final logs = await session.getAllLogsAsString();
          onError(logs ?? 'Lỗi FFmpeg không xác định');
          _session = null;
          _onStateChanged?.call();
        }
      },
          (log) => print('FFmpeg log: ${log.getMessage()}'),
    );

    _onStateChanged?.call();
  }

  // Dừng streaming
  Future<void> stopStreaming() async {
    if (_session != null) {
      await _session!.cancel();
      _session = null;
      _onStateChanged?.call();
    }
  }

  // Kiểm tra trạng thái streaming
  bool get isStreaming => _session != null;

  // Cập nhật trạng thái hiển thị bảng tỷ số
  void updateScoreboardVisibility(bool isVisible) {
    _isScoreboardVisible = isVisible;
  }
}