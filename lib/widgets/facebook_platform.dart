// File: lib/widgets/facebook_platform.dart
// Mô tả: Widget quản lý và hiển thị giao diện phát trực tiếp Facebook
// Hỗ trợ đăng nhập, cấu hình và kiểm soát phát trực tiếp

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:vnvar_flutter/widgets/scoreboard_input_screen.dart';
import '../utils/ffmpeg_fb.dart';
import '../services/scoreboard_service.dart';

class FacebookPlatform extends StatefulWidget {
  final BuildContext context;
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;
  final Function(String?, String?) onTitleUpdated;
  final bool isScoreboardVisible;
  final Function(bool) onScoreboardVisibilityChanged;

  const FacebookPlatform({
    required this.context,
    required this.onPlatformSelected,
    required this.streamKeyController,
    required this.onTitleUpdated,
    required this.isScoreboardVisible,
    required this.onScoreboardVisibilityChanged,
    Key? key,
  }) : super(key: key);

  @override
  _FacebookPlatformState createState() => _FacebookPlatformState();
}

class _FacebookPlatformState extends State<FacebookPlatform> {
  // Các thuộc tính cơ bản
  late FFmpegFB _ffmpegFB;
  final TextEditingController _titleController = TextEditingController();

  // Trạng thái người dùng
  bool _isLoggedIn = false;
  String? _userName;
  String? _accessToken;

  // Trạng thái giao diện
  bool _obscureText = true;
  bool _isStreaming = false;
  late bool _isScoreboardVisible;

  @override
  void initState() {
    super.initState();
    _setupServices();
    _checkLoginStatus();
  }

  // Thiết lập các dịch vụ cần thiết
  void _setupServices() {
    // Khởi tạo trạng thái bảng điểm
    _isScoreboardVisible = widget.isScoreboardVisible;

    // Thiết lập FFmpeg với callback
    _ffmpegFB = FFmpegFB(
      onStateChanged: () => mounted ? setState(() {}) : null,
      isScoreboardVisible: widget.isScoreboardVisible,
      getScoreboardVisibility: () => widget.isScoreboardVisible,
    );

    // Đăng ký lắng nghe cập nhật bảng điểm
    ScoreboardService().onScoreboardUpdated = () {
      if (_isStreaming && widget.isScoreboardVisible && mounted) {
        // Xử lý khi bảng điểm cập nhật trong quá trình livestream
      }
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  //---------------------------
  // XÁC THỰC FACEBOOK
  //---------------------------

  // Kiểm tra trạng thái đăng nhập khi khởi động
  Future<void> _checkLoginStatus() async {
    final accessToken = await FacebookAuth.instance.accessToken;
    if (accessToken != null && mounted) {
      try {
        final userData = await FacebookAuth.instance.getUserData(fields: "name");
        setState(() {
          _userName = userData['name'];
          _isLoggedIn = true;
          _accessToken = accessToken.tokenString;
        });
        widget.onTitleUpdated(null, _accessToken);
      } catch (e) {
        // Xử lý lỗi nếu cần
      }
    }
  }

  // Xử lý quá trình đăng nhập
  Future<void> _login() async {
    try {
      // Yêu cầu quyền truy cập
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'publish_video']
      );

      if (result.status == LoginStatus.success && mounted) {
        // Lấy thông tin người dùng và token
        final userData = await FacebookAuth.instance.getUserData(fields: "name");
        final token = result.accessToken?.tokenString;

        // Cập nhật trạng thái
        setState(() {
          _userName = userData['name'];
          _isLoggedIn = true;
          _accessToken = token;
        });

        widget.onTitleUpdated(null, _accessToken);
        _showSnackBar('Đăng nhập thành công: Xin chào $_userName');
      } else if (mounted) {
        _showSnackBar('Đăng nhập thất bại: ${result.message}');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi: $e');
    }
  }

  // Xử lý đăng xuất
  Future<void> _logout() async {
    try {
      await FacebookAuth.instance.logOut();

      if (mounted) {
        setState(() {
          _accessToken = null;
          _userName = null;
          _isLoggedIn = false;
          _titleController.clear();
        });
        widget.onTitleUpdated(null, null);
        _showSnackBar('Đã đăng xuất');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi khi đăng xuất: $e');
    }
  }

  //---------------------------
  // QUẢN LÝ LIVESTREAM
  //---------------------------

  // Bắt đầu phát sóng trực tiếp
  void _startLiveStream() {
    // Kiểm tra điều kiện để bắt đầu
    if (!_isLoggedIn && widget.streamKeyController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng đăng nhập hoặc nhập Stream Key để bắt đầu livestream');
      return;
    }

    // Cập nhật UI
    setState(() => _isStreaming = true);

    // Bắt đầu phát sóng qua FFmpeg
    _ffmpegFB.startStreaming(
      streamKey: widget.streamKeyController.text.trim(),
      accessToken: _accessToken,
      title: _titleController.text.trim(),
      onError: (error) => mounted ? _showSnackBar('Lỗi khi bắt đầu stream: $error') : null,
    );

    _showSnackBar('Đang livestream');
  }

  // Dừng phát sóng trực tiếp
  void _stopLiveStream() {
    _ffmpegFB.stopStreaming();
    setState(() => _isStreaming = false);
    _showSnackBar('Livestream đã dừng');
  }

  //---------------------------
  // DIALOGS & NOTIFICATIONS
  //---------------------------

  // Hiển thị thông báo
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(widget.context).showSnackBar(
          SnackBar(content: Text(message))
      );
    }
  }

  // Hiển thị dialog nhập tiêu đề
  void _showTitleDialog() {
    showDialog(
      context: widget.context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhập tiêu đề Livestream'),
        content: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Tiêu đề',
            hintText: 'Nhập tiêu đề cho livestream',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final title = _titleController.text.trim();
              if (title.isNotEmpty) {
                widget.onTitleUpdated(title, _accessToken);
                _showSnackBar('Tiêu đề đã được lưu: $title');
              } else {
                _showSnackBar('Vui lòng nhập tiêu đề');
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // Hiển thị dialog nhập Stream Key
  void _showStreamKeyDialog() {
    showDialog(
      context: widget.context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhập Stream Key cho Facebook'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return TextField(
              controller: widget.streamKeyController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Stream Key',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF4e7fff),
                  ),
                  onPressed: () {
                    setDialogState(() => _obscureText = !_obscureText);
                  },
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showSnackBar('Stream Key đã được lưu');
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  //---------------------------
  // UI COMPONENTS
  //---------------------------

  // Công tắc bật/tắt hiển thị bảng tỷ số
  Widget _buildScoreboardToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Hiện bảng tỷ số', style: TextStyle(fontSize: 16)),
        Switch(
          value: _isScoreboardVisible,
          onChanged: (value) {
            setState(() => _isScoreboardVisible = value);
            widget.onScoreboardVisibilityChanged(value);
          },
          activeColor: const Color(0xFF346ED7),
        ),
      ],
    );
  }

  // Nút điều khiển livestream (bắt đầu/dừng)
  Widget _buildStreamButton() {
    // Nút dừng phát sóng
    if (_ffmpegFB.isStreaming) {
      return _buildButton(
        onPressed: _stopLiveStream,
        icon: Icons.stop,
        label: 'Dừng Livestream',
        backgroundColor: Colors.red.withOpacity(0.8),
        borderColor: Colors.red,
      );
    }

    // Nút bắt đầu phát sóng
    else {
      return _buildButton(
        onPressed: _startLiveStream,
        icon: Icons.play_circle,
        label: 'Bắt đầu Livestream',
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF346ED7), Color(0xFF084CCC)],
        ),
        borderColor: const Color(0xFF4e7fff),
      );
    }
  }

  // Tạo nút với giao diện đồng nhất
  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color? backgroundColor,
    LinearGradient? gradient,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nút quay lại
          Container(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => widget.onPlatformSelected(null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),

          // Nội dung chính
          Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: Column(
              children: [
                // Lời chào người dùng
                if (_isLoggedIn && _userName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Xin chào $_userName',
                      style: const TextStyle(
                        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Nút đăng nhập/nhập tiêu đề
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: _isLoggedIn ? _showTitleDialog : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _isLoggedIn ? 'Nhập tiêu đề' : 'Đăng nhập',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Các tùy chọn dựa trên trạng thái đăng nhập
                ..._isLoggedIn
                    ? _buildLoggedInControls()
                    : _buildGuestControls(),

                // Công tắc hiển thị bảng tỷ số
                const SizedBox(height: 16),
                _buildScoreboardToggle(),

                // Hiển thị bảng điểm nếu được bật
                if (_isScoreboardVisible) ...[
                  const SizedBox(height: 16),
                  ScoreboardInput(),
                ],

                // Nút bắt đầu/dừng phát trực tiếp
                const SizedBox(height: 16),
                Center(child: _buildStreamButton()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Các điều khiển khi người dùng chưa đăng nhập
  List<Widget> _buildGuestControls() {
    return [
      const SizedBox(height: 8),
      SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: _showStreamKeyDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Nhập Stream Key',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    ];
  }

  // Các điều khiển khi người dùng đã đăng nhập
  List<Widget> _buildLoggedInControls() {
    return [
      const SizedBox(height: 8),
      SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Đăng xuất',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    ];
  }
}