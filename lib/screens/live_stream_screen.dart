import 'package:flutter/material.dart';
import '../controller/live_stream_controller.dart';
import '../controller/rtsp_preview_controller.dart';
import '../widgets/live_stream_widgets.dart';

class LiveStreamScreen extends StatefulWidget {
  final String rtspUrl;

  const LiveStreamScreen({Key? key, required this.rtspUrl}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final TextEditingController _streamKeyController = TextEditingController();
  late RtspPreviewController _previewController;
  late LiveStreamController _controller;
  String? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    // Khởi tạo _controller với platform mặc định là 'YouTube'
    _controller = LiveStreamController(
      rtspUrl: widget.rtspUrl,
      streamKeyController: _streamKeyController,
      onStateChange: setState,
      context: context,
      platform: _selectedPlatform ?? 'YouTube', // Mặc định là YouTube
    );
    _previewController = RtspPreviewController(rtspUrl: widget.rtspUrl);
    _previewController.initialize();
    _previewController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {
      if (_previewController.previewImagePath != null) {
        imageCache.clear();
        imageCache.clearLiveImages();
      }
    });
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
          // Background gradient phủ toàn màn hình
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
          // Nội dung cuộn
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
                      // Cập nhật lại _controller khi nền tảng thay đổi
                      _controller = LiveStreamController(
                        rtspUrl: widget.rtspUrl,
                        streamKeyController: _streamKeyController,
                        onStateChange: setState,
                        context: context,
                        platform: _selectedPlatform ?? 'YouTube', // Đảm bảo luôn có giá trị
                      );
                    });
                  },
                  onStartStream: _controller.startLiveStream,
                  onStopStream: _controller.stopLiveStream,
                  streamKeyController: _streamKeyController,
                  selectedPlatform: _selectedPlatform,
                  previewImagePath: _previewController.previewImagePath,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}