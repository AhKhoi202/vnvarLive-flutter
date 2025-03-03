import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

class RtspPreviewController extends ChangeNotifier {
  final String rtspUrl;
  String? previewImagePath; // Đường dẫn đến hình ảnh preview
  bool isGeneratingPreview = false; // Trạng thái đang tạo preview

  RtspPreviewController({required this.rtspUrl});

  /// Khởi tạo và lấy một hình ảnh mới từ luồng RTSP
  Future<void> initialize() async {
    if (isGeneratingPreview) return;

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
      final command = '-rtsp_transport tcp -i $rtspUrl -frames:v 1 -q:v 2 -y $outputPath';

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