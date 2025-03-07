// D:\AndroidStudioProjects\vnvar_flutter\lib\widgets\facebook_platform.dart
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookPlatform extends StatefulWidget {
  final BuildContext context;
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;
  final Function(String?, String?) onTitleUpdated; // Callback để gửi tiêu đề

  const FacebookPlatform({
    required this.context,
    required this.onPlatformSelected,
    required this.streamKeyController,
    required this.onTitleUpdated, // Thêm tham số mới
    Key? key,
  }) : super(key: key);

  @override
  _FacebookPlatformState createState() => _FacebookPlatformState();
}

class _FacebookPlatformState extends State<FacebookPlatform> {
  bool _obscureText = true;
  String? _userName;
  bool _isLoggedIn = false;
  final TextEditingController _titleController = TextEditingController();
  String? _accessToken; // Lưu _accessToken trong state

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Kiểm tra trạng thái đăng nhập và lấy thông tin user nếu đã đăng nhập
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
        widget.onTitleUpdated(null, _accessToken); // Gửi _accessToken khi khởi tạo
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  // Hàm đăng nhập
  Future<void> _login() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'publish_video'],
      );
      if (result.status == LoginStatus.success && mounted) {
        final userData = await FacebookAuth.instance.getUserData(fields: "name");
        setState(() {
          _userName = userData['name'];
          _isLoggedIn = true;
        });
        print('Access Token: $_accessToken'); // Print the access token here
        widget.onTitleUpdated(null, null); // Gửi null khi đăng xuất
        ScaffoldMessenger.of(widget.context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thành công: Xin chào $_userName')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(widget.context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thất bại: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(widget.context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  // Hàm đăng xuất
  Future<void> _logout() async {
    try {
      await FacebookAuth.instance.logOut();
      if (mounted) {
        setState(() {
          _userName = null;
          _isLoggedIn = false;
          _titleController.clear();
        });
        ScaffoldMessenger.of(widget.context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(widget.context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

  // Hàm hiển thị dialog nhập title
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
                widget.onTitleUpdated(title, _accessToken); // Gửi tiêu đề lên cấp trên
                ScaffoldMessenger.of(widget.context).showSnackBar(
                  SnackBar(content: Text('Tiêu đề đã được lưu: $title')),
                );
              } else {
                ScaffoldMessenger.of(widget.context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => widget.onPlatformSelected(null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: Column(
            children: [
              // Hiển thị text "Xin chào [username]" màu đen khi đã đăng nhập
              if (_isLoggedIn && _userName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Xin chào $_userName',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Hiển thị nút "Đăng nhập" hoặc "Cá nhân" tùy trạng thái
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: _isLoggedIn ? _showTitleDialog : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isLoggedIn ? 'Cá nhân' : 'Đăng nhập',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
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
                                    setDialogState(() {
                                      _obscureText = !_obscureText;
                                      print('Obscure text changed to: $_obscureText');
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);

                              ScaffoldMessenger.of(widget.context).showSnackBar(
                                const SnackBar(content: Text('Stream Key đã được lưu')),
                              );
                            },
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Nhập Stream Key',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              // Nút đăng xuất hiển thị khi đã đăng nhập
              if (_isLoggedIn) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}