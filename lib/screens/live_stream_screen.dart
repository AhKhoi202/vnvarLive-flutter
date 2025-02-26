import 'package:flutter/material.dart';
import '../controller/live_stream_controller.dart';
import '../widgets/live_stream_widgets.dart';

class LiveStreamScreen extends StatefulWidget {
  final String rtspUrl;

  const LiveStreamScreen({Key? key, required this.rtspUrl}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final TextEditingController _streamKeyController = TextEditingController();
  late final LiveStreamController _controller;
  String? _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _controller = LiveStreamController(
      rtspUrl: widget.rtspUrl,
      streamKeyController: _streamKeyController,
      onStateChange: setState,
      context: context,
    );
  }

  @override
  void dispose() {
    _streamKeyController.dispose();
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
        backgroundColor: Colors.lightBlue,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: buildPlatformSelectionScreen(
            context: context,
            isStreaming: _controller.isStreaming,
            onPlatformSelected: (platform) {
              setState(() => _selectedPlatform = platform);
            },
            onStartStream: _controller.startLiveStream,
            onStopStream: _controller.stopLiveStream,
            streamKeyController: _streamKeyController,
            selectedPlatform: _selectedPlatform, // Truyền tham số này
          ),
        ),
      ),
    );
  }
}