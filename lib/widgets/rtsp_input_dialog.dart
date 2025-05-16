// D:\VNDC\VNVAR Livestream\MobileApp\Android_BuildOnWindows\lib\widgets\rtsp_input_dialog.dart
import 'package:flutter/material.dart';

class RtspInputDialog extends StatefulWidget {
  final String initialValue;

  const RtspInputDialog({
    Key? key,
    this.initialValue = '',
  }) : super(key: key);

  @override
  State<RtspInputDialog> createState() => _RtspInputDialogState();
}

class _RtspInputDialogState extends State<RtspInputDialog> {
  late TextEditingController _rtspController;
  bool _hasText = false; // Biến để kiểm tra có văn bản trong TextField không

  @override
  void initState() {
    super.initState();
    _rtspController = TextEditingController(text: widget.initialValue);
    _hasText = _rtspController.text.isNotEmpty; // Khởi tạo trạng thái ban đầu

    // listener để theo dõi thay đổi trong TextField
    _rtspController.addListener(() {
      setState(() {
        _hasText = _rtspController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _rtspController.dispose();
    super.dispose();
  }

  // Phương thức để xóa toàn bộ nội dung
  void _clearText() {
    _rtspController.clear();
    // Đặt focus trở lại vào TextField sau khi xóa
    FocusScope.of(context).unfocus();
    Future.delayed(Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'NHẬP RTSP URL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _rtspController,
              decoration: InputDecoration(
                labelText: 'RTSP URL',
                labelStyle: const TextStyle(color: Color(0xFF4e7fff)),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4e7fff), width: 2),
                ),
                suffixIcon: _hasText
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Color(0xFF4e7fff)),
                  onPressed: _clearText,
                )
                    : null,
              ),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final rtspUrl = _rtspController.text.trim();
                    Navigator.pop(context, rtspUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}