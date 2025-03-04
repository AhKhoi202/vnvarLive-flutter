// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\liveScreen.dart
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

class LiveStreamScreen extends StatefulWidget {
  final String rtspUrl;

  const LiveStreamScreen({Key? key, required this.rtspUrl}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final TextEditingController _streamKeyController = TextEditingController();
  bool _isStreaming = false;
  String? _selectedPlatform; // Track the selected platform

  // Hàm bắt đầu livestream (unchanged)
// Trong class _LiveStreamScreenState
  Future<void> _startLiveStream(String rtspUrl, String streamKey) async {
    if (_isStreaming) {
      await _stopLiveStream();
    }

    setState(() {
      _isStreaming = true;
    });

    // Tạo RTMP URL từ stream key
    // final rtmpUrl = "rtmps://live-api-s.facebook.com:443/rtmp/$streamKey";
    final rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey";

    // Lệnh FFmpeg từ yêu cầu của bạn
    final command =
        '-rtsp_transport tcp -fflags nobuffer -i "$rtspUrl" -c:v libx264 -preset veryfast -b:v 4000k -maxrate 4000k -bufsize 8000k -r 30 -c:a aac -b:a 128k -ar 44100 -ac 2 -g 25 -keyint_min 25 -tune zerolatency -f flv "$rtmpUrl"';

    FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Streaming started successfully')),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isStreaming = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Streaming failed: ${await session.getFailStackTrace()}')),
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Streaming started successfully')),
    );
  }
  // Hàm dừng livestream (unchanged)
  Future<void> _stopLiveStream() async {
    if (_isStreaming) {
      FFmpegKit.cancel();

      setState(() {
        _isStreaming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livestream stopped successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active livestream to stop')),
      );
    }
  }

  @override
  void dispose() {
    _streamKeyController.dispose();
    if (_isStreaming) {
      _stopLiveStream();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background as per your code
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
          child: _selectedPlatform == 'FACEBOOK'
              ? _buildFACEBOOKStreamKeyScreen() // Show FACEBOOK-specific screen
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Camera preview section
              Container(
                height: 200, // Adjust height as needed
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black, // Black background for the video preview
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ), // Play icon as a placeholder for the video
                ),
              ),
              const SizedBox(height: 16),
              // Platform selection
              Align(
                alignment: Alignment.centerLeft, // Align text to the left
                child: Text(
                  'Nền tảng phát sóng: ?',
                  style: TextStyle(
                    color: Colors.black, // Changed to black to match white background
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPlatform = 'FACEBOOK';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'FACEBOOK',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30), // Added spacing before the livestream buttons
              // Livestream control buttons (as in your original code)
              Center(
                child: !_isStreaming
                    ? ElevatedButton.icon(
                  onPressed: () {
                    final streamKey = _streamKeyController.text.trim();
                    if (streamKey.isNotEmpty) {
                      _startLiveStream(widget.rtspUrl, streamKey);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập Stream Key')),
                      );
                    }
                  },
                  icon: const Icon(Icons.live_tv),
                  label: const Text('Bắt đầu Livestream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
                    : ElevatedButton.icon(
                  onPressed: _stopLiveStream,
                  icon: const Icon(Icons.stop),
                  label: const Text('Dừng Livestream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build the FACEBOOK stream key screen as shown in the screenshot
  Widget _buildFACEBOOKStreamKeyScreen() {
    return Scaffold(
      backgroundColor: Colors.black87, // Dark background to match the screenshot
      appBar: AppBar(
        backgroundColor: Colors.red, // Red app bar as in the screenshot
        title: const Text(
          'FACEBOOK',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _selectedPlatform = null; // Return to the main screen
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _streamKeyController,
              decoration: InputDecoration(
                labelText: 'Nhập stream key',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20), // Spacing before the back button, if needed
          ],
        ),
      ),
    );
  }
}