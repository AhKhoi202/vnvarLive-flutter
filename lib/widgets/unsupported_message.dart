// widget thông báo không hỗ trợ
import 'package:flutter/material.dart';

Widget buildUnsupportedPlatformMessage(BuildContext context, String platform) {
  return Padding(
    padding: const EdgeInsets.only(top: 32.0),
    child: Text(
      'Nền tảng $platform chưa được hỗ trợ',
      style: const TextStyle(color: Colors.black, fontSize: 16),
    ),
  );
}