import 'dart:io';
import 'package:flutter/material.dart';
import 'platform_buttons.dart'; // Import widget nút chọn nền tảng
import 'unsupported_message.dart'; // Import widget thông báo không hỗ trợ

Widget buildPlatformSelectionScreen({
  required BuildContext context,
  required bool isStreaming,
  required Function(String?) onPlatformSelected,
  required VoidCallback onStartStream,
  required VoidCallback onStopStream,
  required TextEditingController streamKeyController,
  String? selectedPlatform,
  String? previewImagePath,
}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(8.0),
        width: double.infinity,
        child: Text(
          previewImagePath != null
              ? 'Hình ảnh minh họa từ RTSP'
              : 'Không kết nối được với RTSP',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: previewImagePath != null
            ? Image.file(
          File(previewImagePath),
          fit: BoxFit.cover,
          key: ValueKey(previewImagePath),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.error, color: Colors.red, size: 50),
          ),
        )
            : const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        height: 215,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(1),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Text(
                selectedPlatform != null
                    ? 'Nền tảng phát sóng: $selectedPlatform'
                    : 'Nền tảng phát sóng: ?',
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (selectedPlatform == null || selectedPlatform == 'YouTube')
                    buildPlatformButtons(
                      context: context,
                      onPlatformSelected: onPlatformSelected,
                      selectedPlatform: selectedPlatform,
                      streamKeyController: streamKeyController,
                    )
                  else
                    buildUnsupportedPlatformMessage(context, selectedPlatform),
                ],
              ),
            ),
          ],
        ),
      ),
      if (isStreaming) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber, width: 1),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vui lòng không tắt màn hình hoặc thoát app khi đang livestream',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
      if (selectedPlatform != null) ...[
        const SizedBox(height: 30),
        Center(
          child: !isStreaming
              ? InkWell(
            onTap: onStartStream,
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
                  border: Border.all(color: const Color(0xFF4e7fff), width: 2),
                ),
                child: ElevatedButton.icon(
                  onPressed: onStartStream,
                  icon: const Icon(Icons.play_circle, color: Colors.white),
                  label: const Text(
                    'Bắt đầu Livestream',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            onTap: onStopStream,
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
                  onPressed: onStopStream,
                  icon: const Icon(Icons.stop, color: Colors.white),
                  label: const Text(
                    'Dừng Livestream',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    ],
  );
}