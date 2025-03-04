import 'package:flutter/material.dart';

Widget buildPlatformButtons({
  required BuildContext context,
  required Function(String?) onPlatformSelected,
  String? selectedPlatform,
  required TextEditingController streamKeyController,
}) {
  // Biến để kiểm soát trạng thái ẩn/hiện Stream Key
  bool _obscureText = true;

  if (selectedPlatform == 'YouTube') {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => onPlatformSelected(null),
                  ),
                ],
              ),
              TextField(
                controller: streamKeyController,
                obscureText: _obscureText, // Ẩn Stream Key mặc định
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
                        _obscureText = !_obscureText; // Đổi trạng thái ẩn/hiện
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            ],
          );
        },
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.only(top: 32.0),
    child: Column(
      children: [
        SizedBox(
          width: 300,
          child: ElevatedButton(
            onPressed: () => onPlatformSelected('YouTube'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'YouTube',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 300,
          child: ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nền tảng Facebook chưa được hỗ trợ')),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Facebook',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 300,
          child: ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nền tảng Tùy chỉnh chưa được hỗ trợ')),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tùy chỉnh',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    ),
  );
}