// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\live_stream_screen.dart
import 'package:flutter/material.dart';
import '../controller/live_stream_controller.dart';
import '../controller/rtsp_preview_controller.dart';
import '../widgets/live_stream_widgets.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);
  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final TextEditingController _streamKeyController = TextEditingController();
  late RtspPreviewController _previewController; // Still late, but properly initialized
  late LiveStreamController _controller;
  String? _selectedPlatform;
  String? _liveStreamTitle; // Thêm biến để lưu tiêu đề

  @override
  void initState() {
    super.initState();
    _previewController = RtspPreviewController();
    // Then initialize _controller
    _controller = LiveStreamController(
      streamKeyController: _streamKeyController,
      onStateChange: setState,
      context: context,
      platform: _selectedPlatform ?? 'YouTube', // Default to YouTube
      liveStreamTitle: _liveStreamTitle, // Truyền tiêu đề vào controller
    );
    // Initialize _previewController first
    _previewController = RtspPreviewController();
    _previewController.initialize(); // Lấy hình ảnh
    _previewController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {}); // Cập nhật UI khi hình ảnh thay đổi
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Stack(
        children: [
          // Background gradient covering the entire screen
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF104891), Color(0xFF107c90)],
              ),
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Center(
                child: buildPlatformSelectionScreen(
                  context: context,
                  isStreaming: _controller.isStreaming,
                  onPlatformSelected: (platform) {
                    setState(() {
                      _selectedPlatform = platform;
                      // Update _controller when platform changes
                      _controller = LiveStreamController(
                        streamKeyController: _streamKeyController,
                        onStateChange: setState,
                        context: context,
                        platform: _selectedPlatform ?? 'YouTube',
                        liveStreamTitle: _liveStreamTitle,
                      );
                    });
                  },
                  onStartStream: _controller.startLiveStream,
                  onStopStream: _controller.stopLiveStream,
                  streamKeyController: _streamKeyController,
                  selectedPlatform: _selectedPlatform,
                  previewImagePath: _previewController.previewImagePath,
                  onTitleUpdated: (title) {
                    setState(() {
                      _liveStreamTitle = title; // Cập nhật tiêu đề
                      _controller = LiveStreamController(
                        streamKeyController: _streamKeyController,
                        onStateChange: setState,
                        context: context,
                        platform: _selectedPlatform ?? 'Facebook',
                        liveStreamTitle: _liveStreamTitle, // Truyền tiêu đề mới
                      );
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}