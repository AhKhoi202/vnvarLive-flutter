import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để sao chép vào clipboard
import '../controller/live_stream_controller.dart';
import '../services/youtube_service.dart';
import '../utils/ffmpeg_helper.dart';

class YouTubePlatform extends StatefulWidget {
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;
  final LiveStreamController controller;

  const YouTubePlatform({
    required this.onPlatformSelected,
    required this.streamKeyController,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  _YouTubePlatformState createState() => _YouTubePlatformState();
}

class _YouTubePlatformState extends State<YouTubePlatform> {
  final YoutubeService _youtubeService = YoutubeService();
  final FFmpegHelper _ffmpegHelper = FFmpegHelper();
  bool _obscureText = true;
  String? _userName;
  bool _isLoggedIn = false;
  String _statusMessage = 'Sẵn sàng';
  String? _liveUrl;
  bool _isProcessing = false;
  bool _streamIsActive = false;
  bool _isStreaming = false; // Trạng thái đang phát trực tiếp

  @override
  void initState() {
    super.initState();
    _youtubeService.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _youtubeService.currentUser = account;
          _isLoggedIn = account != null;
        });
        if (account != null) {
          _handleGetToken();
        }
      }
    });
    _youtubeService.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _youtubeService.signIn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại: $error')),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _youtubeService.signOut();
      if (mounted) {
        setState(() {
          _userName = null;
          _isLoggedIn = false;
          _liveUrl = null;
          _isProcessing = false;
          _streamIsActive = false;
          _isStreaming = false;
          _statusMessage = 'Sẵn sàng';
        });
        _ffmpegHelper.cancelSession();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $error')),
        );
      }
    }
  }

  Future<void> _handleGetToken() async {
    try {
      await _youtubeService.getToken();
      await _getUserInfo();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy token: $error')),
        );
      }
    }
  }

  Future<void> _getUserInfo() async {
    try {
      final userName = await _youtubeService.getUserName();
      if (mounted) {
        setState(() {
          _userName = userName;
        });
      }
    } catch (error) {
      print('User info error: $error');
    }
  }

  Future<void> _prepareLiveStream() async {
    if (_youtubeService.accessToken == null) {
      _showSnackBar('Vui lòng đăng nhập trước');
      return;
    }
    if (_isProcessing) {
      _showSnackBar('Đang xử lý, vui lòng đợi');
      return;
    }

    setState(() {
      _isProcessing = true;
      _streamIsActive = false;
      _statusMessage = 'Đang tạo broadcast và stream...';
    });

    try {
      await _youtubeService.createLiveBroadcastAndStream();
      if (mounted) {
        setState(() {
          _liveUrl = _youtubeService.liveUrl;
          _statusMessage = 'Đang gửi luồng...';
          print(_liveUrl);
        });
      }

      await _ffmpegHelper.startStreaming(
        _youtubeService.streamKey!,
        onError: (error) => _showSnackBar('Lỗi khi gửi luồng: $error'),
      );

      if (mounted) {
        setState(() => _statusMessage = 'Đang chờ luồng hoạt động...');
      }
      for (int i = 0; i < 12; i++) {
        await Future.delayed(const Duration(seconds: 5));
        print('Đang chờ luồng hoạt động...${5 * (i + 1)}s');
        if (await _youtubeService.isStreamActive()) {
          if (mounted) {
            setState(() {
              _streamIsActive = true;
              _statusMessage = 'Luồng đã sẵn sàng';
            });
            _showSnackBar('Luồng đã được YouTube xác nhận');
          }
          break;
        }
        if (i == 11) throw Exception('Luồng không hoạt động sau 60 giây');
      }
    } catch (error) {
      _showSnackBar('Lỗi khi chuẩn bị: $error');
      await _stopLiveStream();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _startLiveStream() async {
    if (!_streamIsActive) {
      _showSnackBar('Luồng chưa sẵn sàng, vui lòng chuẩn bị trước');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang bắt đầu livestream...';
    });

    try {
      await _youtubeService.startLiveStream();
      if (mounted) {
        setState(() {
          _isStreaming = true;
          _statusMessage = 'Đang phát trực tiếp';
        });
        _showSnackBar('Đã bắt đầu phát trực tiếp: $_liveUrl');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Lỗi khi bắt đầu livestream: $error');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _stopLiveStream() async {
    if (!_isProcessing && !_streamIsActive) {
      _showSnackBar('Không có luồng nào đang hoạt động');
      return;
    }

    setState(() => _statusMessage = 'Đang dừng...');
    try {
      await _ffmpegHelper.cancelSession();
      await _youtubeService.stopLiveStream();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _streamIsActive = false;
          _isStreaming = false;
          _statusMessage = 'Sẵn sàng';
          _liveUrl = null;
        });
        _showSnackBar('Đã dừng phát trực tiếp');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Lỗi khi dừng: $error');
      }
    }
  }

  void _showStreamKeyDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhập Stream Key cho YouTube'),
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
              if (widget.streamKeyController.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stream Key đã được lưu')),
                );
                print('Stream key entered: ${widget.streamKeyController.text}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập stream key')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _copyLiveUrl() {
    if (_liveUrl != null) {
      Clipboard.setData(ClipboardData(text: _liveUrl!));
      _showSnackBar('Đã sao chép URL phát trực tiếp');
    }
  }

  @override
  void dispose() {
    _ffmpegHelper.cancelSession();
    super.dispose();
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
                  onPressed: _isLoggedIn ? null : _handleSignIn,
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
              if (!_isLoggedIn) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: _showStreamKeyDialog,
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
                    onPressed: _isProcessing ? null : _prepareLiveStream,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Chuẩn bị Livestream',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: _handleSignOut,
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
              const SizedBox(height: 16),
              if (_isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Trạng thái: $_statusMessage',
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
              if (_isStreaming && _liveUrl != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Địa chỉ phát trực tiếp: ',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    Flexible(
                      child: Text(
                        _liveUrl!,
                        style: const TextStyle(color: Colors.blue, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
                      onPressed: _copyLiveUrl,
                      tooltip: 'Sao chép URL',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: !_isStreaming
                    ? InkWell(
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
                        border: Border.all(color: const Color(0xFF4e7fff), width: 2),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _startLiveStream,
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
          ),
        ),
      ],
    );
  }
}