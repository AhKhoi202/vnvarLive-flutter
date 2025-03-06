// D:\AndroidStudioProjects\vnvar_flutter\lib\controller\rtsp_preview_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm import này

class RtspPreviewController extends ChangeNotifier {
  String? _rtspUrl; // Lưu trữ RTSP URL lấy từ SharedPreferences
  String? previewImagePath; // Đường dẫn đến hình ảnh preview
  bool isGeneratingPreview = false; // Trạng thái đang tạo preview

  RtspPreviewController() {
    _loadRtspUrl(); // Tự động tải rtspUrl khi khởi tạo
  }

  /// Tải RTSP URL từ SharedPreferences
  Future<void> _loadRtspUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _rtspUrl = prefs.getString('rtspUrl');
    notifyListeners(); // Cập nhật nếu cần
  }

  /// Khởi tạo và lấy một hình ảnh mới từ luồng RTSP
  Future<void> initialize() async {
    if (isGeneratingPreview) return;

    // Đảm bảo đã tải rtspUrl
    if (_rtspUrl == null || _rtspUrl!.isEmpty) {
      await _loadRtspUrl();
      if (_rtspUrl == null || _rtspUrl!.isEmpty) {
        debugPrint("Không tìm thấy RTSP URL trong SharedPreferences");
        return;
      }
    }

    isGeneratingPreview = true;
    notifyListeners();

    // Xóa ảnh cũ nếu tồn tại
    if (previewImagePath != null && await File(previewImagePath!).exists()) {
      await File(previewImagePath!).delete();
      previewImagePath = null;
    }

    await _generateSingleFrame();

    isGeneratingPreview = false;
    notifyListeners();
  }

  /// Tạo một frame duy nhất từ RTSP với tên file duy nhất
  Future<void> _generateSingleFrame() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath =
          '${tempDir.path}/rtsp_preview_${DateTime.now().millisecondsSinceEpoch}.jpg'; // Tên file duy nhất

      // Command để lấy một frame từ luồng RTSP
      final command = '-rtsp_transport tcp -i $_rtspUrl -frames:v 1 -q:v 2 -y $outputPath';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final file = File(outputPath);
        if (await file.exists()) {
          previewImagePath = outputPath;
          notifyListeners();
        } else {
          debugPrint("Không tìm thấy file ảnh sau khi tạo: $outputPath");
        }
      } else {
        debugPrint("FFmpeg lỗi: ${await session.getFailStackTrace()}");
      }
    } catch (e) {
      debugPrint('Lỗi khi tạo frame từ RTSP: $e');
    }
  }

  /// Dọn dẹp tài nguyên
  @override
  Future<void> dispose() async {
    if (previewImagePath != null && await File(previewImagePath!).exists()) {
      File(previewImagePath!).delete().catchError((e) {
        debugPrint("Lỗi khi xóa file preview: $e");
      });
    }
    previewImagePath = null;
    super.dispose();
  }
}