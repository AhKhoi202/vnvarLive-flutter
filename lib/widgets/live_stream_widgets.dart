import 'dart:io';
import 'package:flutter/material.dart';

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
                    _buildPlatformButtons(
                      context: context,
                      onPlatformSelected: onPlatformSelected,
                      selectedPlatform: selectedPlatform,
                      streamKeyController: streamKeyController,
                    )
                  else
                    _buildUnsupportedPlatformMessage(context, selectedPlatform),
                ],
              ),
            ),
          ],
        ),
      ),
      // Hiển thị cảnh báo khi đang phát trực tiếp
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
      // Chỉ hiển thị nút livestream khi đã chọn nền tảng
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

// Widget phụ để xây dựng các nút chọn nền tảng hoặc phần nhập stream key
Widget _buildPlatformButtons({
  required BuildContext context,
  required Function(String?) onPlatformSelected,
  String? selectedPlatform,
  required TextEditingController streamKeyController,
}) {
  if (selectedPlatform == 'YouTube') {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0), // Thêm padding để không đè lên text
      child: Column(
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
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
  // Nếu chưa chọn nền tảng, hiển thị các nút chọn nền tảng
  return Padding(
    padding: const EdgeInsets.only(top: 32.0), // Thêm padding để không đè lên text
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

// Widget phụ để hiển thị thông báo khi nền tảng không được hỗ trợ
Widget _buildUnsupportedPlatformMessage(BuildContext context, String platform) {
  return Padding(
    padding: const EdgeInsets.only(top: 32.0), // Thêm padding để không đè lên text
    child: Text(
      'Nền tảng $platform chưa được hỗ trợ',
      style: const TextStyle(color: Colors.black, fontSize: 16),
    ),
  );
}