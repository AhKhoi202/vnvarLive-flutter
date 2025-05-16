// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/rtsp_input_dialog.dart';
import '../utils/url_validator.dart';
import 'live_stream_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _rtspController = TextEditingController();
  String? _savedRtspUrl;

  @override
  void initState() {
    super.initState();
    // Tải URL đã lưu khi màn hình khởi tạo
    _loadSavedRtspUrl();
  }

  @override
  void dispose() {
    _rtspController.dispose();
    super.dispose();
  }

  // Hàm tải RTSP URL từ SharedPreferences
  Future<void> _loadSavedRtspUrl() async {
    print('Loading saved RTSP URL...');
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('rtspUrl');

    setState(() {
      _savedRtspUrl = savedUrl;
      // Nếu có URL đã lưu, thiết lập nó vào controller
      if (savedUrl != null) {
        _rtspController.text = savedUrl;
      }
    });
    print('Loaded RTSP URL: $_savedRtspUrl');
  }

  // Hàm lưu RTSP URL vào SharedPreferences
  Future<void> _saveRtspUrl(String rtspUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rtspUrl', rtspUrl);
  }

  // Mở livestream với URL đã lưu trước đó
  void _openSavedStream() {
    print('Saved RTSP URL: $_savedRtspUrl');
    if (_savedRtspUrl != null && isValidRtspUrl(_savedRtspUrl!)) {
      _navigateToLiveStreamScreen(_savedRtspUrl!);
    } else {
      // Hiển thị thông báo nếu URL không hợp lệ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL đã lưu không hợp lệ. Vui lòng nhập URL mới.')),
      );
    }
  }

  void _navigateToLiveStreamScreen(String rtspUrl) {
    _saveRtspUrl(rtspUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamScreen(),
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

      // Kiểm tra và thêm tiền tố rtsp:// nếu cần
      String processedUrl = result.trim();
      if (!processedUrl.startsWith('rtsp://')) {
        processedUrl = 'rtsp://$processedUrl';
      }

      if (isValidRtspUrl(processedUrl)) {
        _navigateToLiveStreamScreen(processedUrl);
      } else {
        // Hiển thị thông báo bằng AlertDialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Lỗi'),
            content: Text('URL RTSP không hợp lệ. Vui lòng nhập đúng định dạng rtsp://'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
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

      // Kiểm tra và thêm tiền tố rtsp:// nếu cần
      String processedUrl = result.trim();
      if (!processedUrl.startsWith('rtsp://')) {
        processedUrl = 'rtsp://$processedUrl';
      }

      if (isValidRtspUrl(processedUrl)) {
        _navigateToLiveStreamScreen(processedUrl);
      } else {
        // Hiển thị thông báo bằng AlertDialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Lỗi'),
            content: Text('URL RTSP không hợp lệ. Vui lòng nhập đúng định dạng rtsp://'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFF3AB0E4),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: TextTheme(
          headlineMedium: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF30A4DD),
          ),
          bodySmall: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white70,
          ),
        ),
      ),
      home: ScaffoldMessenger(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 8,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF15273F), Color(0xFF0C3862)],
                ),
              ),
            ),
            title: const Text(
              'Giải pháp VNVAR Livestream ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF104891), Color(0xFF107c90)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 24.0, right: 24.0, bottom: 50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/vnvar_white.png',
                    width: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'Không thể tải logo',
                        style: TextStyle(color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                  // Nút "Quét mã QR" - Hình vuông
                  InkWell(
                    onTap: _showQRScannerDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 125,
                        height: 125,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: const Color(0xFFffffff), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code, size: 40, color: Color(0xFFffffff)),
                              const SizedBox(height: 8),
                              Text(
                                'QUÉT MÃ QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFFffffff),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // THÊM NÚT TRUY CẬP NHANH KHI CÓ URL ĐÃ LƯU
                  if (_savedRtspUrl != null) ...[
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: _openSavedStream,
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(color: const Color(0xFFffffff), width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_circle, size: 28, color: Color(0xFFffffff)),
                                const SizedBox(width: 8),
                                Text(
                                  'SỬ DỤNG RTSP ĐÃ LƯU',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: const Color(0xFFffffff),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Nút "Nhập đường dẫn stream" - Kích thước tự động theo nội dung
                  InkWell(
                    onTap: _showRtspInputDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: const Color(0xFFffffff), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.link, size: 28, color: Color(0xFFffffff)),
                              const SizedBox(width: 8),
                              Text(
                                'NHẬP ĐƯỜNG DẪN RTSP',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFFffffff),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}