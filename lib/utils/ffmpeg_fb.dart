// D:\AndroidStudioProjects\vnvar_flutter\lib\utils\ffmpeg_fb.dart
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FFmpegFB {
  FFmpegSession? _session;
  String? _rtspUrl;
  static const String _facebookApiUrl = 'https://graph.facebook.com/v19.0/me/live_videos';
  final Function()? _onStateChanged; // Callback để thông báo thay đổi trạng thái

  FFmpegFB({Function()? onStateChanged}) : _onStateChanged = onStateChanged {
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

    final ffmpegCommand = [
      '-rtsp_transport', 'tcp',
      '-fflags', 'nobuffer',
      '-i', '"$_rtspUrl"',
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
      '"$rtmpUrl"'
    ].join(' ');

    _session = await FFmpegKit.executeAsync(
      ffmpegCommand,
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

    _onStateChanged?.call(); // Thông báo trạng thái thay đổi sau khi bắt đầu
  }

  // Dừng streaming
  Future<void> stopStreaming() async {
    if (_session != null) {
      await _session!.cancel();
      _session = null;
      _onStateChanged?.call(); // Thông báo trạng thái thay đổi sau khi dừng
    }
  }

  // Kiểm tra trạng thái streaming
  bool get isStreaming => _session != null;

}