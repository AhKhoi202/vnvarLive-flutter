import 'package:flutter/material.dart';

Widget buildPlatformSelection({
  required BuildContext context,
  required Function(String?) onPlatformSelected,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 0),
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
            onPressed: () => onPlatformSelected('Facebook'),
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