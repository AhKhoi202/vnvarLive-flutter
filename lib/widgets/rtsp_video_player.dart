// D:\AndroidStudioProjects\vnvar_flutter\lib\widgets\rtsp_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RtspVideoPlayer extends StatefulWidget {
  final String rtspUrl;

  const RtspVideoPlayer({
    Key? key,
    required this.rtspUrl,
  }) : super(key: key);

  @override
  State<RtspVideoPlayer> createState() => _RtspVideoPlayerState();
}

class _RtspVideoPlayerState extends State<RtspVideoPlayer> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.rtspUrl),
    );

    try {
      await _videoController.initialize();
      await _videoController.play();
      await _videoController.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _hasError
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                'Không thể kết nối',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        )
            : !_isInitialized
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                'Đang kết nối...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        )
            : Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            ),
            // Overlay cho các điều khiển nếu cần
          ],
        ),
      ),
    );
  }
}