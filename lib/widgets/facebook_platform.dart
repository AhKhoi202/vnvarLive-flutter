// D:\AndroidStudioProjects\vnvar_flutter\lib\widgets\facebook_platform.dart
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../utils/ffmpeg_fb.dart';
import 'scoreboard_input_screen.dart'; // Import màn hình nhập bảng tỷ số

class FacebookPlatform extends StatefulWidget {
  final BuildContext context;
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;
  final Function(String?, String?) onTitleUpdated;

  const FacebookPlatform({
    required this.context,
    required this.onPlatformSelected,
    required this.streamKeyController,
    required this.onTitleUpdated,
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
  String? _accessToken;
  late FFmpegFB _ffmpegFB;
  bool _isScoreboardVisible = false; // Thêm biến này


  @override
  void initState() {
    super.initState();
    _ffmpegFB = FFmpegFB(
      onStateChanged: () {
        if (mounted) {
          setState(() {}); // Rebuild giao diện khi trạng thái thay đổi
        }
      },
      isScoreboardVisible: _isScoreboardVisible, // Truyền trạng thái ban đầu
    );
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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
        print("_accessToken _checkLoginStatus: $_accessToken");
        widget.onTitleUpdated(null, _accessToken);
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> _login() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'publish_video'],
      );
      if (result.status == LoginStatus.success && mounted) {
        final userData = await FacebookAuth.instance.getUserData(fields: "name");
        final token = result.accessToken?.tokenString;
        setState(() {
          _userName = userData['name'];
          _isLoggedIn = true;
          _accessToken = token;
        });
        print('Access Token _login: $_accessToken');
        widget.onTitleUpdated(null, _accessToken);
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
        ScaffoldMessenger.of(widget.context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất')),
        );
        print("_logout _accessToken: $_accessToken === _userName :$_userName");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(widget.context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

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

  void _startLiveStream() {
    if (!_isLoggedIn && widget.streamKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(widget.context).showSnackBar(
        const SnackBar(
            content: Text(
                'Vui lòng đăng nhập hoặc nhập Stream Key để bắt đầu livestream')),
      );
      return;
    }

    _ffmpegFB.startStreaming(
      streamKey: widget.streamKeyController.text.trim(),
      accessToken: _accessToken,
      title: _titleController.text.trim(),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(widget.context).showSnackBar(
            SnackBar(content: Text('Lỗi khi bắt đầu stream: $error')),
          );
        }
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(widget.context).showSnackBar(
        const SnackBar(content: Text('Đang livestream')),
      );
    }
  }

  void _stopLiveStream() {
    _ffmpegFB.stopStreaming();
    if (mounted) {
      ScaffoldMessenger.of(widget.context).showSnackBar(
        const SnackBar(content: Text('Livestream đã dừng')),
      );
    }
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
                    _isLoggedIn ? 'Nhập tiêu đề' : 'Đăng nhập',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              if (!_isLoggedIn) ...[
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
              ],
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
              if (!_ffmpegFB.isStreaming) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hiện bảng tỷ số',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    const SizedBox(width: 0),
                    Switch(
                      value: _isScoreboardVisible, // Thêm biến trạng thái mới
                      onChanged: (value) {
                        setState(() {
                          _isScoreboardVisible = value;
                          _ffmpegFB.updateScoreboardVisibility(value); // Cập nhật trạng thái trong FFmpegYT
                        });
                      },
                      activeColor: const Color(0xFF346ED7),
                    ),
                  ],
                ),
              ],
              if (_isScoreboardVisible) ...[
                const SizedBox(height: 16),
                 ScoreboardInput(), // Sử dụng SizedBox thay vì Expanded
              ],
              const SizedBox(height: 16),
              Center(
                child: _ffmpegFB.isStreaming
                    ? InkWell(
                  onTap: _stopLiveStream,
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
                        onPressed: _stopLiveStream,
                        icon: const Icon(Icons.stop, color: Colors.white),
                        label: const Text(
                          'Dừng Livestream',
                          style: TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
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
                  onTap: _startLiveStream,
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
                        border: Border.all(
                            color: const Color(0xFF4e7fff), width: 2),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _startLiveStream,
                        icon: const Icon(Icons.play_circle,
                            color: Colors.white),
                        label: const Text(
                          'Bắt đầu Livestream',
                          style: TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
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
          ),
        ),
      ],
    );
  }
}