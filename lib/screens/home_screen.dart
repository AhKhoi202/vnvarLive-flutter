import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Thêm package này nếu muốn dùng Poppins
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/rtsp_input_dialog.dart';
import '../utils/url_validator.dart';
import 'live_stream_screen.dart';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

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

  void _navigateToLiveStreamScreen(String rtspUrl) {
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
        _navigateToLiveStreamScreen(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã QR không chứa URL RTSP hợp lệ')),
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
        _navigateToLiveStreamScreen(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL RTSP không hợp lệ hoặc trống')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFF3AB0E4), // Giữ màu chính cho tham chiếu
        scaffoldBackgroundColor: Colors.transparent, // Để hỗ trợ gradient
        textTheme: TextTheme(
          headlineMedium: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF30A4DD), // Giữ màu text nút là #30A4DD
          ),
          bodySmall: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white70,
          ),
        ),
      ),
      home: Scaffold(
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
            'Giải pháp livestream VNVAR',
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
              colors: [Color(0xFF104891), Color(0xFF107c90)], // Giữ gradient body hiện tại
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 24.0, right: 24.0, bottom: 50.0),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/vnvar_white.png', // Đường dẫn đến logo (đã kiểm tra và khớp)
                    width: 200, // Kích thước chiều rộng của logo (có thể điều chỉnh)
                    fit: BoxFit.contain, // Đảm bảo logo không bị méo
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'Không thể tải logo',
                        style: TextStyle(color: Colors.white),
                      ); // Hiển thị thông báo nếu logo không tải được
                    },
                  ),
                  const SizedBox(height: 80),
                  // Nút "Quét mã QR" - Hình vuông
                  InkWell(
                    onTap: _showQRScannerDialog,
                    borderRadius: BorderRadius.circular(16),
                    onHover: (hovering) {
                      if (hovering) {
                        // Có thể thêm hiệu ứng khác nếu cần
                      }
                    },
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 125, // Kích thước vuông (chiều rộng = chiều cao)
                        height: 125, // Kích thước vuông (chiều rộng = chiều cao)
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), // Trong suốt với lớp mờ
                          border: Border.all(
                              color: const Color(0xFFffffff), width: 2), // Border màu #30A4DD
                          borderRadius: BorderRadius.circular(16), // Bo góc mềm mại
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12), // Padding đều cho hình vuông
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 40, color: Color(0xFFffffff)),
                              const SizedBox(height: 8),
                              Text(
                                'QUÉT MÃ QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFffffff), // Text màu #30A4DD
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Nút "Nhập đường dẫn stream" - Kích thước tự động theo nội dung
                  InkWell(
                    onTap: _showRtspInputDialog,
                    borderRadius: BorderRadius.circular(16),
                    onHover: (hovering) {
                      if (hovering) {
                        // Có thể thêm hiệu ứng khác nếu cần
                      }
                    },
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), // Trong suốt với lớp mờ
                          border: Border.all(
                              color: const Color(0xFFffffff), width: 2), // Border màu #30A4DD
                          borderRadius: BorderRadius.circular(16), // Bo góc mềm mại
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Tự động điều chỉnh kích thước theo nội dung
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link, size: 28, color: Color(0xFFffffff)),
                              const SizedBox(width: 8),
                              Text(
                                'NHẬP ĐƯỜNG DẪN RTSP',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFffffff), // Text màu #30A4DD
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
    );
  }
}