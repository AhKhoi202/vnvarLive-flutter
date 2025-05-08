import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để sao chép vào clipboard
import '../services/youtube_service.dart';
import '../utils/ffmpeg_yt.dart';
import '../services/scoreboard_service.dart'; // Thêm import này

class YouTubePlatform extends StatefulWidget {
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;
  final bool isScoreboardVisible;
  final Function(bool) onScoreboardVisibilityChanged;

  const YouTubePlatform({
    required this.onPlatformSelected,
    required this.streamKeyController,
    required this.isScoreboardVisible , // Giá trị mặc định
    required this.onScoreboardVisibilityChanged,
    Key? key,
  }) : super(key: key);

  @override
  _YouTubePlatformState createState() => _YouTubePlatformState();
}

class _YouTubePlatformState extends State<YouTubePlatform> {
  final YoutubeService _youtubeService = YoutubeService();
  late FFmpegYT _ffmpegHelper;
  bool _obscureText = true;
  String? _userName;
  bool _isLoggedIn = false;
  String _statusMessage = 'Vui lòng chuẩn bị trước khi livestream';
  String? _liveUrl;
  bool _isProcessing = false;
  bool _streamIsActive = false;
  bool _isStreaming = false;
  bool _isManualStream = false;
  final TextEditingController _titleController = TextEditingController();
  String _privacyStatus = 'unlisted';
  bool _isCommentaryEnabled = false;
  bool _isMicEnabled = false;

  @override
  void initState() {
    super.initState();
    _ffmpegHelper = FFmpegYT( isScoreboardVisible: widget.isScoreboardVisible, // Giá trị ban đầu
      getScoreboardVisibility: () => widget.isScoreboardVisible,);

    // Đăng ký callback để cập nhật khi bảng điểm thay đổi
    final scoreboardService = ScoreboardService();
    print('ckeck livestream. _isStreaming: $_isStreaming,isScoreboardVisible: ${widget.isScoreboardVisible} ');

    scoreboardService.onScoreboardUpdated = () {
      // Nếu đang phát trực tiếp và bảng điểm đang hiển thị
      if (_isStreaming && widget.isScoreboardVisible && mounted) {
        print('Bảng tỷ số đã được cập nhật trong livestream');
        // Có thể thêm logic cụ thể nếu cần
      }
    };

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
      await _stopLiveStream();
      if (mounted) {
        setState(() {
          _userName = null;
          _isLoggedIn = false;
          _liveUrl = null;
          _isProcessing = false;
          _streamIsActive = false;
          _isStreaming = false;
          _isManualStream = false;
          _statusMessage = 'Sẵn sàng';
        });
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

  Future<void> _combinedPrepareThenStream() async {
    if (_isProcessing || _isStreaming) {
      _showSnackBar('Đang xử lý hoặc đã phát trực tiếp');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang chuẩn bị và bắt đầu livestream...';
    });

    try {
      if (_isLoggedIn) {
        // Nếu chưa chuẩn bị, thực hiện quá trình chuẩn bị trước
        if (!_streamIsActive) {
          // Tự động tạo tiêu đề nếu người dùng chưa nhập
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = 'Livestream ${DateTime.now().toString().substring(0, 16)}';
          }

          // Quá trình chuẩn bị livestream
          await _youtubeService.createLiveBroadcastAndStream(
            title: _titleController.text.trim(),
            privacyStatus: _privacyStatus,
          );

          if (mounted) {
            setState(() {
              _liveUrl = _youtubeService.liveUrl;
              _statusMessage = 'Đang gửi luồng...';
            });
          }

          await _ffmpegHelper.startStreaming(
            _youtubeService.streamKey!,
            onError: (error) => _showSnackBar('Lỗi khi gửi luồng: $error'),
          );

          // Kiểm tra xem luồng đã hoạt động chưa
          for (int i = 0; i < 12; i++) {
            await Future.delayed(const Duration(seconds: 5));
            if (await _youtubeService.isStreamActive()) {
              if (mounted) {
                setState(() {
                  _streamIsActive = true;
                  _statusMessage = 'Luồng đã sẵn sàng, đang bắt đầu phát trực tiếp...';
                });
              }
              break;
            }
            if (i == 11) throw Exception('Luồng không hoạt động sau 60 giây');
          }
        }

        // Bắt đầu phát trực tiếp
        await _youtubeService.startLiveStream();
      } else {
        // Chế độ streamKey thủ công
        if (widget.streamKeyController.text.isEmpty) {
          throw Exception('Vui lòng nhập Stream Key');
        }
        _isManualStream = true;
        await _ffmpegHelper.startStreaming(
          widget.streamKeyController.text,
          onError: (error) => _showSnackBar('Lỗi khi gửi luồng: $error'),
        );
      }

      if (mounted) {
        setState(() {
          _isStreaming = true;
          _streamIsActive = true;
          _statusMessage = 'Đang phát trực tiếp';
          if (_isLoggedIn) _liveUrl = _youtubeService.liveUrl;
        });
        _showSnackBar('Đã bắt đầu phát trực tiếp');
      }
    } catch (error) {
      _showSnackBar('Lỗi khi chuẩn bị/bắt đầu livestream: $error');
      // Dọn dẹp nếu có lỗi
      await _stopLiveStream();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _startLiveStream() async {
    if (_isProcessing || _isStreaming) {
      _showSnackBar('Đang xử lý hoặc đã phát trực tiếp');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang bắt đầu livestream...';
    });

    try {
      if (_isLoggedIn) {
        if (!_streamIsActive) {
          throw Exception('Luồng chưa sẵn sàng, vui lòng chuẩn bị trước');
        }
        await _youtubeService.startLiveStream();
      } else {
        if (widget.streamKeyController.text.isEmpty) {
          throw Exception('Vui lòng nhập Stream Key');
        }
        _isManualStream = true;
        await _ffmpegHelper.startStreaming(
          widget.streamKeyController.text,
          onError: (error) => _showSnackBar('Lỗi khi gửi luồng: $error'),
        );
      }

      if (mounted) {
        setState(() {
          _isStreaming = true;
          _streamIsActive = true;
          _statusMessage = 'Đang phát trực tiếp';
          if (_isLoggedIn) _liveUrl = _youtubeService.liveUrl;
        });
        _showSnackBar('Đã bắt đầu phát trực tiếp');
      }
    } catch (error) {
      _showSnackBar('Lỗi khi bắt đầu livestream: $error');
      setState(() {
        _isProcessing = false;
        _isStreaming = false;
        _streamIsActive = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _stopLiveStream() async {
    if (!_isStreaming) {
      _showSnackBar('Không có luồng nào đang hoạt động');
      return;
    }

    setState(() => _statusMessage = 'Đang dừng...');
    try {
      await _ffmpegHelper.cancelSession();
      if (_isLoggedIn && !_isManualStream) {
        await _youtubeService.stopLiveStream();
      }
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _streamIsActive = false;
          _isStreaming = false;
          _isManualStream = false;
          _statusMessage = 'Vui lòng chuẩn bị trước khi livestream';
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
                _showSnackBar('Stream Key đã được lưu');
              } else {
                _showSnackBar('Vui lòng nhập Stream Key');
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

  void _showTitleDialog() {
    showDialog(
      context: context,
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

  @override
  void dispose() {
    _ffmpegHelper.cancelSession();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị cảnh báo khi đang livestream
    if (_isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Đang Livestream'),
            content: const Text('Đang livestream, vui lòng không tắt thiết bị để tránh gián đoạn.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      });
    }
    return SingleChildScrollView(
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => widget.onPlatformSelected(null),
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
                if (!_isLoggedIn) ...[
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed:_isStreaming ? null : _showStreamKeyDialog,
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
                      onPressed: _isProcessing || _isStreaming ? null : _showTitleDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Nhập tiêu đề',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chế độ: ',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      DropdownButton<String>(
                        value: _privacyStatus,
                        items: const [
                          DropdownMenuItem(value: 'public', child: Text('Công khai')),
                          DropdownMenuItem(value: 'unlisted', child: Text('Không công khai')),
                          DropdownMenuItem(value: 'private', child: Text('Riêng tư')),
                        ],
                        onChanged: _isProcessing || _isStreaming
                            ? null
                            : (value) {
                          setState(() {
                            _privacyStatus = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: _isStreaming ? null : _handleSignOut,
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
                if (_isLoggedIn) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Trạng thái: $_statusMessage',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ),
                ],
                if (_isStreaming && _liveUrl != null && !_isManualStream) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Địa chỉ live: ',
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
                      ),
                    ],
                  ),
                ],
                if (!_isStreaming) ...[
                  // const SizedBox(height: 8),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text(
                  //       'Bình luận',
                  //       style: TextStyle(color: Colors.black, fontSize: 14),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     Switch(
                  //       value: _isCommentaryEnabled,
                  //       onChanged: (value) {
                  //         setState(() {
                  //           _isCommentaryEnabled = value;
                  //         });
                  //       },
                  //       activeColor: const Color(0xFF346ED7),
                  //     ),
                  //   ],
                  // ),
                  if (_isCommentaryEnabled) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Micro',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        Switch(
                          value: _isMicEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isMicEnabled = value;
                            });
                          },
                          activeColor: const Color(0xFF346ED7),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Center(
                  child: !_isStreaming
                      ? InkWell(
                    onTap: _isProcessing ? null : _combinedPrepareThenStream,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isProcessing
                            ? null
                            : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF346ED7), Color(0xFF084CCC)],
                        ),
                        color: _isProcessing ? Colors.grey[400] : null,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _isProcessing ? Colors.grey : const Color(0xFF4e7fff),
                            width: 2
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _combinedPrepareThenStream,
                        icon: _isProcessing
                            ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                        )
                            : const Icon(Icons.play_circle, color: Colors.white),
                        label: Text(
                          _isProcessing ? 'Đang xử lý...' : 'Bắt đầu Livestream',
                          style: TextStyle(
                              color: _isProcessing ? Colors.grey[300] : Colors.white,
                              fontSize: 18
                          ),
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
                  )
                      : InkWell(
                    onTap: _stopLiveStream,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}