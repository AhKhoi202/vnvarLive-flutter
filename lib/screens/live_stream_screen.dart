// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\live_stream_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../controller/rtsp_preview_controller.dart';
import '../widgets/scoreboard_overlay.dart';
import '../widgets/youtube_platform.dart'; // Import YouTube
import '../widgets/facebook_platform.dart'; // Import Facebook
import '../widgets/platform_selection.dart'; // Import danh sách chọn nền tảng
import '../widgets/unsupported_message.dart'; // Import widget thông báo không hỗ trợ

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final TextEditingController _streamKeyController = TextEditingController();
  late RtspPreviewController _previewController;
  String? _selectedPlatform;
  String? _liveStreamTitle;
  String? _accessToken;
  bool _isInitializing = true;
  bool _isScoreboardVisible = false; // Trạng thái bảng tỷ số
  bool _isManualScoreMode = true; // Trạng thái chế độ nhập điểm thủ công

@override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    try {
      _previewController = RtspPreviewController();
      await _previewController.initialize();
      _previewController.addListener(_updateState);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _streamKeyController.dispose();
    _previewController.removeListener(_updateState);
    _previewController.dispose();
    super.dispose();
  }

  Widget buildPlatformSelectionScreen({
    required BuildContext context,
    required bool isStreaming,
    required Function(String?) onPlatformSelected,
    required TextEditingController streamKeyController,
    String? selectedPlatform,
    String? previewImagePath,
    String? liveStreamTitle,
    String? accessToken,
    required Function(String?, String?) onTitleUpdated,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          width: double.infinity,
          child: Text(
            previewImagePath != null
                ? 'Hình ảnh minh họa từ RTSP'
                : 'Không kết nối được với RTSP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack( // Thay Image.file bằng Stack để hiển thị overlay
              children: [
                previewImagePath != null
                    ? Image.file(
                  File(previewImagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  key: ValueKey(previewImagePath),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  ),
                )
                    : const Center(
                  child: CircularProgressIndicator(),
                ),
                // Thêm overlay cho bảng tỷ số nếu được bật
                if (_isScoreboardVisible)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: ScoreboardOverlay(
                      isManualMode: _isManualScoreMode,
                    ), // overlay bảng tỷ số
                  ),
              ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
          child: Text(
            selectedPlatform != null
                ? 'Nền tảng phát sóng: $selectedPlatform'
                : 'Nền tảng phát sóng: ?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selectedPlatform == null)
                buildPlatformSelection(
                  context: context,
                  onPlatformSelected: onPlatformSelected,
                )
              else if (selectedPlatform == 'YouTube')
                YouTubePlatform(
                  onPlatformSelected: onPlatformSelected,
                  streamKeyController: streamKeyController,
                  isScoreboardVisible: _isScoreboardVisible, // Thêm dòng này
                  onScoreboardVisibilityChanged: (isVisible) { // Thêm callback này
                    setState(() {
                      _isScoreboardVisible = isVisible;
                    });
                  },
                )
              else if (selectedPlatform == 'Facebook')
                  FacebookPlatform(
                    context: context,
                    onPlatformSelected: onPlatformSelected,
                    streamKeyController: streamKeyController,
                    onTitleUpdated: onTitleUpdated,
                    isScoreboardVisible: _isScoreboardVisible, // Thêm dòng này
                    onScoreboardVisibilityChanged: (isVisible) { // Thêm callback này
                      setState(() {
                        _isScoreboardVisible = isVisible;
                      });
                    },
                  )
                else
                  buildUnsupportedPlatformMessage(context, selectedPlatform),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 8,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15273F), Color(0xFF0C3862)],
            ),
          ),
        ),
        title: const Text(
          'Live Stream',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // thêm nút cài đặt nếu cần
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF104891), Color(0xFF107c90)],
          ),
        ),
        child: _isInitializing
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: buildPlatformSelectionScreen(
              context: context,
              isStreaming: false,
              onPlatformSelected: (platform) {
                setState(() {
                  _selectedPlatform = platform;
                });
              },
              streamKeyController: _streamKeyController,
              selectedPlatform: _selectedPlatform,
              previewImagePath: _previewController.previewImagePath,
              liveStreamTitle: _liveStreamTitle,
              accessToken: _accessToken,
              onTitleUpdated: (title, accessToken) {
                setState(() {
                  _liveStreamTitle = title;
                  _accessToken = accessToken;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
