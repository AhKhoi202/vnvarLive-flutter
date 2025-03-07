// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\live_stream_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../controller/live_stream_controller.dart';
import '../controller/rtsp_preview_controller.dart';
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
  late LiveStreamController _controller;
  String? _selectedPlatform;
  String? _liveStreamTitle;
  String? _accessToken;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    try {
      _previewController = RtspPreviewController();
      await _previewController.initialize();
      _controller = LiveStreamController(
        streamKeyController: _streamKeyController,
        onStateChange: setState,
        context: context,
        platform: _selectedPlatform ?? 'YouTube',
        liveStreamTitle: _liveStreamTitle,
        accessToken: _accessToken,
      );
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
    if (_controller.isStreaming) {
      _controller.stopLiveStream();
    }
    super.dispose();
  }

  // Hàm buildPlatformSelectionScreen được tích hợp trực tiếp vào đây
  Widget buildPlatformSelectionScreen({
    required BuildContext context,
    required bool isStreaming,
    required Function(String?) onPlatformSelected,
    required VoidCallback onStartStream,
    required VoidCallback onStopStream,
    required TextEditingController streamKeyController,
    String? selectedPlatform,
    String? previewImagePath,
    String? liveStreamTitle,
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
          child: previewImagePath != null
              ? Image.file(
            File(previewImagePath),
            fit: BoxFit.cover,
            key: ValueKey(previewImagePath),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.error, color: Colors.red, size: 50),
            ),
          )
              : const Center(
            child: CircularProgressIndicator(),
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
                )
              else if (selectedPlatform == 'Facebook')
                  FacebookPlatform(
                    context: context,
                    onPlatformSelected: onPlatformSelected,
                    streamKeyController: streamKeyController,
                    onTitleUpdated: onTitleUpdated,
                  )
                else
                  buildUnsupportedPlatformMessage(context, selectedPlatform),
            ],
          ),
        ),
        if (isStreaming) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vui lòng không tắt màn hình hoặc thoát app khi đang livestream',
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (selectedPlatform != null) ...[
          const SizedBox(height: 30),
          Center(
            child: !isStreaming
                ? InkWell(
              onTap: onStartStream,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF346ED7),
                        Color(0xFF084CCC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(color: const Color(0xFF4e7fff), width: 2),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onStartStream,
                    icon: const Icon(Icons.play_circle, color: Colors.white),
                    label: const Text(
                      'Bắt đầu Livestream',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            )
                : InkWell(
              onTap: onStopStream,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onStopStream,
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text(
                      'Dừng Livestream',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
              isStreaming: _controller.isStreaming,
              onPlatformSelected: (platform) {
                setState(() {
                  _selectedPlatform = platform;
                  _controller = LiveStreamController(
                    streamKeyController: _streamKeyController,
                    onStateChange: setState,
                    context: context,
                    platform: _selectedPlatform ?? 'YouTube',
                    liveStreamTitle: _liveStreamTitle,
                    accessToken: _accessToken,
                  );
                });
              },
              onStartStream: _controller.startLiveStream,
              onStopStream: _controller.stopLiveStream,
              streamKeyController: _streamKeyController,
              selectedPlatform: _selectedPlatform,
              previewImagePath: _previewController.previewImagePath,
              liveStreamTitle: _liveStreamTitle,
              onTitleUpdated: (title, accessToken) {
                setState(() {
                  _liveStreamTitle = title;
                  _accessToken = accessToken;
                  _controller = LiveStreamController(
                    streamKeyController: _streamKeyController,
                    onStateChange: setState,
                    context: context,
                    platform: _selectedPlatform ?? 'YouTube',
                    liveStreamTitle: _liveStreamTitle,
                    accessToken: _accessToken,
                  );
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}