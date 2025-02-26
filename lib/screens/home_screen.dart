import 'package:flutter/material.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/rtsp_input_dialog.dart';
import '../utils/url_validator.dart';
import 'live_stream_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _rtspController = TextEditingController();

  @override
  void dispose() {
    _rtspController.dispose();
    super.dispose();
  }

  void _navigateToLiveScreen(String rtspUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamScreen(rtspUrl: rtspUrl),
      ),
    );
  }

  void _showQRScannerDialog() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => QRScannerDialog(),
    );

    if (result != null) {
      setState(() {
        _rtspController.text = result;
      });

      if (isValidRtspUrl(result)) {
        _navigateToLiveScreen(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã QR không chứa URL RTSP hợp lệ'),
          ),
        );
      }
    }
  }

  void _showRtspInputDialog() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => RtspInputDialog(initialValue: _rtspController.text),
    );

    if (result != null) {
      setState(() {
        _rtspController.text = result;
      });

      if (isValidRtspUrl(result)) {
        _navigateToLiveScreen(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL RTSP không hợp lệ hoặc trống'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'VNVAR LIVE',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _showQRScannerDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'QUÉT MÃ QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Icon(
                      Icons.qr_code,
                      color: Colors.blue,
                      size: 50,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng Dùng thông tin lần trước chưa được triển khai'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Dùng thông tin lần trước',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showRtspInputDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Nhập đường dẫn stream',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}