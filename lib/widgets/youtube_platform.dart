// D:\AndroidStudioProjects\vnvar_flutter\lib\widgets\youtube_platform.dart
import 'package:flutter/material.dart';
import '../controller/live_stream_controller.dart';

class YouTubePlatform extends StatefulWidget {
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;
  final LiveStreamController controller; // Thêm controller

  const YouTubePlatform({
    required this.onPlatformSelected,
    required this.streamKeyController,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  _YouTubePlatformState createState() => _YouTubePlatformState();
}

class _YouTubePlatformState extends State<YouTubePlatform> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => widget.onPlatformSelected(null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: TextField(
            controller: widget.streamKeyController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Nhập stream key',
              labelStyle: const TextStyle(color: Color(0xFF4e7fff)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4e7fff), width: 2),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4e7fff), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4e7fff), width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF4e7fff),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                    print('Obscure text changed to: $_obscureText');
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: !widget.controller.isStreaming
              ? InkWell(
            onTap: widget.controller.startLiveStream,
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
                  onPressed: widget.controller.startLiveStream,
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
            onTap: widget.controller.stopLiveStream,
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
                  onPressed: widget.controller.stopLiveStream,
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
    );
  }
}