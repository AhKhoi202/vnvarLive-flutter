// File: lib/widgets/youtube_platform.dart
// Mô tả: Widget quản lý và hiển thị giao diện phát trực tiếp YouTube
// Hỗ trợ đăng nhập, cấu hình và kiểm soát phát trực tiếp

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vnvar_flutter/widgets/scoreboard_input_screen.dart';
import '../services/youtube_service.dart';
import '../utils/ffmpeg_yt.dart';
import '../services/scoreboard_service.dart';

// Widget quản lý và hiển thị giao diện phát trực tiếp YouTube
class YouTubePlatform extends StatefulWidget {
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;
  final bool isScoreboardVisible;
  final Function(bool) onScoreboardVisibilityChanged;

  const YouTubePlatform({
    required this.onPlatformSelected,
    required this.streamKeyController,
    required this.isScoreboardVisible,
    required this.onScoreboardVisibilityChanged,
    Key? key,
  }) : super(key: key);

  @override
  _YouTubePlatformState createState() => _YouTubePlatformState();
}

class _YouTubePlatformState extends State<YouTubePlatform> {
  //---------------------------
  // SERVICES & CONTROLLERS
  //---------------------------
  final YoutubeService _youtubeService = YoutubeService();
  late FFmpegYT _ffmpegHelper;
  final TextEditingController _titleController = TextEditingController();

  //---------------------------
  // STATE VARIABLES
  //---------------------------
  // Trạng thái xác thực
  bool _isLoggedIn = false;
  String? _userName;

  // Trạng thái giao diện
  bool _obscureText = true;
  bool _isScoreboardVisible = false;
  String _statusMessage = 'Vui lòng chuẩn bị trước khi livestream';

  // Trạng thái phát trực tiếp
  String? _liveUrl;
  bool _isProcessing = false;
  bool _streamIsActive = false;
  bool _isStreaming = false;
  bool _isManualStream = false;

  // Cài đặt phát trực tiếp
  String _privacyStatus = 'unlisted';
  bool _isCommentaryEnabled = false;
  bool _isMicEnabled = false;

  //---------------------------
  // LIFECYCLE METHODS
  //---------------------------
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupListeners();
  }

  // Khởi tạo các dịch vụ cần thiết
  void _initializeServices() {
    _ffmpegHelper = FFmpegYT(
      isScoreboardVisible: widget.isScoreboardVisible,
      getScoreboardVisibility: () => widget.isScoreboardVisible,
    );
    _isScoreboardVisible = widget.isScoreboardVisible;
    _youtubeService.signInSilently();
  }

  // Thiết lập các listeners
  void _setupListeners() {
    // Theo dõi thay đổi người dùng từ YouTube service
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

    // Theo dõi cập nhật bảng điểm
    final scoreboardService = ScoreboardService();
    scoreboardService.onScoreboardUpdated = () {
      if (_isStreaming && widget.isScoreboardVisible && mounted) {
        // Có thể thêm logic cụ thể nếu cần khi bảng điểm cập nhật
      }
    };
  }

  @override
  void dispose() {
    _ffmpegHelper.cancelSession();
    _titleController.dispose();
    super.dispose();
  }

  //---------------------------
  // AUTHENTICATION FUNCTIONS
  //---------------------------

  // Xử lý đăng nhập vào tài khoản YouTube
  Future<void> _handleSignIn() async {
    try {
      await _youtubeService.signIn();
      if (mounted) {
        _showSnackBar('Đăng nhập thành công');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Đăng nhập thất bại: $error');
      }
    }
  }

  // Xử lý đăng xuất khỏi tài khoản YouTube
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
        _showSnackBar('Đã đăng xuất');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Lỗi khi đăng xuất: $error');
      }
    }
  }

  // Lấy token xác thực và thông tin người dùng
  Future<void> _handleGetToken() async {
    try {
      await _youtubeService.getToken();
      await _getUserInfo();
    } catch (error) {
      if (mounted) {
        _showSnackBar('Lỗi khi lấy token: $error');
      }
    }
  }

  // Lấy thông tin người dùng từ YouTube API
  Future<void> _getUserInfo() async {
    try {
      final userName = await _youtubeService.getUserName();
      if (mounted) {
        setState(() {
          _userName = userName;
        });
      }
    } catch (error) {
      // Xử lý lỗi nếu cần thiết
    }
  }

  //---------------------------
  // LIVESTREAM CONTROL
  //---------------------------

  // Kết hợp chuẩn bị và bắt đầu phát trực tiếp
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
        await _prepareAndStartAuthenticatedStream();
      } else {
        await _startManualStream();
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
      await _stopLiveStream();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Chuẩn bị và bắt đầu phát trực tiếp qua tài khoản xác thực
  Future<void> _prepareAndStartAuthenticatedStream() async {
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
      await _waitForStreamActivation();
    }

    // Bắt đầu phát trực tiếp
    await _youtubeService.startLiveStream();
  }

  // Chờ luồng phát trực tiếp hoạt động
  Future<void> _waitForStreamActivation() async {
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (await _youtubeService.isStreamActive()) {
        if (mounted) {
          setState(() {
            _streamIsActive = true;
            _statusMessage = 'Luồng đã sẵn sàng, đang bắt đầu phát trực tiếp...';
          });
        }
        return;
      }
      if (i == 11) throw Exception('Luồng không hoạt động sau 60 giây');
    }
  }

  // Bắt đầu phát trực tiếp thủ công với streamKey
  Future<void> _startManualStream() async {
    if (widget.streamKeyController.text.isEmpty) {
      throw Exception('Vui lòng nhập Stream Key');
    }
    _isManualStream = true;
    await _ffmpegHelper.startStreaming(
      widget.streamKeyController.text,
      onError: (error) => _showSnackBar('Lỗi khi gửi luồng: $error'),
    );
  }

  // Dừng phát trực tiếp
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

  //---------------------------
  // UI HELPERS
  //---------------------------

  // Hiển thị dialog nhập Stream Key
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

  // Hiển thị dialog nhập tiêu đề
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

  // Sao chép URL phát trực tiếp vào clipboard
  void _copyLiveUrl() {
    if (_liveUrl != null) {
      Clipboard.setData(ClipboardData(text: _liveUrl!));
      _showSnackBar('Đã sao chép URL phát trực tiếp');
    }
  }

  // Hiển thị thông báo
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  //---------------------------
  // UI COMPONENTS
  //---------------------------
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(),
          Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: Column(
              children: [
                _buildUserGreeting(),
                if (!_isLoggedIn) _buildGuestControls(),
                if (_isLoggedIn) _buildLoggedInControls(),
                if (_isLoggedIn) _buildStatusSection(),
                _buildStreamControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nút quay lại
  Widget _buildBackButton() {
    return Container(
      alignment: Alignment.topLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => widget.onPlatformSelected(null),
      ),
    );
  }

  // Lời chào người dùng
  Widget _buildUserGreeting() {
    if (_isLoggedIn && _userName != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          'Xin chào $_userName',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // Điều khiển cho người dùng chưa đăng nhập
  Widget _buildGuestControls() {
    return Column(
      children: [
        // Nút đăng nhập
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

        // Nút nhập stream key
        SizedBox(
          width: 300,
          child: ElevatedButton(
            onPressed: _isStreaming ? null : _showStreamKeyDialog,
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
        const SizedBox(height: 8),

        // Công tắc hiển thị bảng điểm
        _buildScoreboardToggle(),

        // Hiển thị bảng điểm nếu được bật
        if (_isScoreboardVisible) ...[
          const SizedBox(height: 16),
          ScoreboardInput(),
        ],
      ],
    );
  }

  // Công tắc bật/tắt bảng điểm
  Widget _buildScoreboardToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Hiện bảng tỷ số',
          style: TextStyle(fontSize: 16),
        ),
        Switch(
          value: _isScoreboardVisible,
          onChanged: (value) {
            setState(() {
              _isScoreboardVisible = value;
            });
            widget.onScoreboardVisibilityChanged(value);
          },
          activeColor: const Color(0xFF346ED7),
        ),
      ],
    );
  }

  // Điều khiển cho người dùng đã đăng nhập
  Widget _buildLoggedInControls() {
    return Column(
      children: [
        // Nút đăng xuất
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
        const SizedBox(height: 8),
        // Nút nhập tiêu đề
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
        // Lựa chọn chế độ riêng tư
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
        // Công tắc hiển thị bảng điểm - thêm vào đây để người dùng đã đăng nhập vẫn thấy
        _buildScoreboardToggle(),
        // Hiển thị bảng điểm nếu được bật
        if (_isScoreboardVisible) ...[
          const SizedBox(height: 16),
          ScoreboardInput(),
        ],
      ],
    );
  }


  // Phần hiển thị trạng thái và URL phát trực tiếp
  Widget _buildStatusSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Hiển thị trạng thái
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Trạng thái: $_statusMessage',
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ),

        // Hiển thị URL phát trực tiếp nếu có
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
      ],
    );
  }

  // Các điều khiển phát trực tiếp
  Widget _buildStreamControls() {
    return Column(
      children: [
        // Tùy chọn bổ sung khi không phát trực tiếp
        if (!_isStreaming && _isCommentaryEnabled) ...[
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

        const SizedBox(height: 16),

        // Nút bắt đầu/dừng phát trực tiếp
        Center(
          child: !_isStreaming
              ? _buildStartStreamingButton()
              : _buildStopStreamingButton(),
        ),
      ],
    );
  }

  // Nút bắt đầu phát trực tiếp
  Widget _buildStartStreamingButton() {
    return InkWell(
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
    );
  }

  // Nút dừng phát trực tiếp
  Widget _buildStopStreamingButton() {
    return InkWell(
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
    );
  }
}