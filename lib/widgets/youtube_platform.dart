// D:\AndroidStudioProjects\vnvar_flutter\lib\widgets\youtube_platform.dart
import 'package:flutter/material.dart';

class YouTubePlatform extends StatefulWidget {
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;

  const YouTubePlatform({
    required this.onPlatformSelected,
    required this.streamKeyController,
    Key? key,
  }) : super(key: key);

  @override
  _YouTubePlatformState createState() => _YouTubePlatformState();
}

class _YouTubePlatformState extends State<YouTubePlatform> {
  bool _obscureText = true; // Biến trạng thái được lưu trong State

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
                    _obscureText = !_obscureText; // Cập nhật trạng thái
                    print('Obscure text changed to: $_obscureText'); // Debug
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}