import 'package:flutter/material.dart';

Widget buildPlatformSelectionScreen({
  required BuildContext context,
  required bool isStreaming,
  required Function(String?) onPlatformSelected,
  required VoidCallback onStartStream,
  required VoidCallback onStopStream,
  required TextEditingController streamKeyController,
  String? selectedPlatform,
}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Nền tảng phát sóng: ?',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      const SizedBox(height: 8),
      // Phần nội dung thay đổi dựa trên nền tảng đã chọn
      if (selectedPlatform == null || selectedPlatform == 'YouTube')
        _buildPlatformButtons(
          context: context,
          onPlatformSelected: onPlatformSelected,
          selectedPlatform: selectedPlatform,
          streamKeyController: streamKeyController,
        )
      else
        _buildUnsupportedPlatformMessage(context, selectedPlatform),
      const SizedBox(height: 30),
      Center(
        child: !isStreaming
            ? ElevatedButton.icon(
          onPressed: onStartStream,
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
          onPressed: onStopStream,
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
      padding: const EdgeInsets.only(top: 2.0), // Thêm padding để căn chỉnh
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // Căn trái để đặt icon ở góc
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black), // Biểu tượng mũi tên quay lại
                onPressed: () => onPlatformSelected(null), // Quay lại chọn nền tảng
              ),
            ],
          ),
          TextField(
            controller: streamKeyController,
            decoration: InputDecoration(
              labelText: 'Nhập stream key',
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            style: const TextStyle(color: Colors.black), // Đổi màu chữ thành đen để phù hợp với nền trắng
          ),
        ],
      ),
    );
  }

  // Nếu chưa chọn nền tảng, hiển thị các nút chọn nền tảng
  return Column(
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
  );
}

// Widget phụ để hiển thị thông báo khi nền tảng không được hỗ trợ
Widget _buildUnsupportedPlatformMessage(BuildContext context, String platform) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      'Nền tảng $platform chưa được hỗ trợ',
      style: const TextStyle(color: Colors.black, fontSize: 16),
    ),
  );
}

// Giữ nguyên widget buildYouTubeStreamKeyScreen vì nó không cần thiết nữa trong trường hợp này
// Bạn có thể xóa hoặc giữ lại để sử dụng trong trường hợp khác

Widget buildYouTubeStreamKeyScreen({
  required TextEditingController streamKeyController,
  required VoidCallback onBack,
}) {
  return Scaffold(
    backgroundColor: Colors.black87,
    appBar: AppBar(
      backgroundColor: Colors.red,
      title: const Text(
        'YouTube',
        style: TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack,
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: streamKeyController,
            decoration: InputDecoration(
              labelText: 'Nhập stream key',
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}