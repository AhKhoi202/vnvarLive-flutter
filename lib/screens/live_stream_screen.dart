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