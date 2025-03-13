import 'package:flutter/material.dart'; // Thư viện Flutter cơ bản cho giao diện
import '../services/youtube_service.dart'; // Dịch vụ xử lý YouTube API
import '../utils/ffmpeg_helper.dart'; // Tiện ích xử lý FFmpeg
import '../constants/api_constants.dart'; // Hằng số API

class YouTubeStreamScreen extends StatefulWidget {
  const YouTubeStreamScreen({Key? key}) : super(key: key); // Constructor với key tùy chọn

  @override
  _YouTubeStreamScreenState createState() => _YouTubeStreamScreenState(); // Tạo state cho widget
}

class _YouTubeStreamScreenState extends State<YouTubeStreamScreen> {
  // Khởi tạo các đối tượng dịch vụ
  final YoutubeService _youtubeService = YoutubeService(); // Dịch vụ YouTube
  final FFmpegHelper _ffmpegHelper = FFmpegHelper(); // Tiện ích FFmpeg

  // Các biến trạng thái
  String _statusMessage = 'Sẵn sàng'; // Thông điệp trạng thái hiển thị trên UI
  String? _userName; // Tên người dùng, nullable vì có thể chưa đăng nhập
  String? _liveUrl; // URL phát trực tiếp, nullable vì chỉ có khi tạo broadcast
  bool _isProcessing = false; // Đang xử lý (tạo broadcast, gửi luồng, v.v.)
  bool _streamIsActive = false; // Luồng đã active trên YouTube chưa

  @override
  void initState() {
    super.initState(); // Gọi initState của lớp cha
    // Lắng nghe sự thay đổi người dùng từ Google Sign-In
    _youtubeService.onCurrentUserChanged.listen((account) {
      setState(() {
        _youtubeService.currentUser = account; // Cập nhật người dùng hiện tại qua setter
      });
      if (account != null) {
        _handleGetToken(); // Lấy token nếu có người dùng
      }
    });
    _youtubeService.signInSilently(); // Thử đăng nhập ngầm khi khởi động
  }

  Future<void> _handleSignIn() async {
    try {
      await _youtubeService.signIn(); // Gọi hàm đăng nhập từ dịch vụ
    } catch (error) {
      _showSnackBar('Đăng nhập thất bại: $error'); // Hiển thị lỗi nếu thất bại
    }
  }

  Future<void> _handleSignOut() async {
    await _youtubeService.signOut(); // Gọi hàm đăng xuất
    setState(() {
      _userName = null; // Xóa tên người dùng
      _liveUrl = null; // Xóa URL phát trực tiếp
      _isProcessing = false; // Reset trạng thái xử lý
      _streamIsActive = false; // Reset trạng thái luồng
      _statusMessage = 'Sẵn sàng'; // Đặt lại thông điệp trạng thái
    });
    _ffmpegHelper.cancelSession(); // Hủy phiên FFmpeg nếu đang chạy
  }

  Future<void> _handleGetToken() async {
    try {
      await _youtubeService.getToken(); // Lấy access token từ Google Sign-In
      await _getUserInfo(); // Lấy thông tin người dùng sau khi có token
    } catch (error) {
      _showSnackBar('Lỗi khi lấy token: $error'); // Hiển thị lỗi nếu thất bại
    }
  }

  Future<void> _getUserInfo() async {
    try {
      final userName = await _youtubeService.getUserName(); // Lấy tên từ API
      setState(() {
        _userName = userName; // Cập nhật tên người dùng lên UI
      });
    } catch (error) {
      print('User info error: $error'); // In lỗi ra console để debug
    }
  }

  Future<void> _prepareLiveStream() async {
    if (_youtubeService.accessToken == null) {
      _showSnackBar('Vui lòng đăng nhập trước'); // Kiểm tra đăng nhập
      return;
    }
    if (_isProcessing) {
      _showSnackBar('Đang xử lý, vui lòng đợi'); // Kiểm tra đang xử lý
      return;
    }

    setState(() {
      _isProcessing = true; // Bắt đầu xử lý
      _streamIsActive = false; // Reset trạng thái luồng
    });

    try {
      setState(() => _statusMessage = 'Đang tạo broadcast và stream...');
      await _youtubeService.createLiveBroadcastAndStream(); // Tạo broadcast và stream
      setState(() {
        _liveUrl = _youtubeService.liveUrl; // Lấy URL phát trực tiếp
        _statusMessage = 'Đang gửi luồng...';
        print(_liveUrl);
      });

      await _ffmpegHelper.startStreaming(
        _youtubeService.streamKey!, // Gửi luồng với stream key
        onError: (error) => _showSnackBar('Lỗi khi gửi luồng: $error'),
      );

      setState(() => _statusMessage = 'Đang chờ luồng hoạt động...');
      for (int i = 0; i < 12; i++) { // Chờ tối đa 30 giây
        await Future.delayed(const Duration(seconds: 5)); // Đợi 5 giây mỗi lần
        print('Đang chờ luồng hoạt động...${5*(i+1)}s');
        print(await _youtubeService.isStreamActive());
        if (await _youtubeService.isStreamActive()) { // Kiểm tra luồng active
          print(5*(i+1));
          print(setState);
          setState(() {
            _streamIsActive = true; // Đánh dấu luồng đã active
            _statusMessage = 'Luồng đã sẵn sàng';
            // _isProcessing = false; // Kết thúc xử lý
          });
          _showSnackBar('Luồng đã được YouTube xác nhận');
          break;
        }
        if (i == 11) throw Exception('Luồng không hoạt động sau 30 giây');
      }
    } catch (error) {
      _showSnackBar('Lỗi khi chuẩn bị: $error');
      await _stopLiveStream(); // Dừng nếu có lỗi
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
      await _youtubeService.startLiveStream(); // Chuyển broadcast sang trạng thái live
      setState(() => _statusMessage = 'Đang phát trực tiếp');
      _showSnackBar('Đã bắt đầu phát trực tiếp: $_liveUrl');
    } catch (error) {
      _showSnackBar('Lỗi khi bắt đầu livestream: $error');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _stopLiveStream() async {
    if (!_isProcessing && !_streamIsActive) {
      _showSnackBar('Không có luồng nào đang hoạt động');
      return;
    }

    setState(() => _statusMessage = 'Đang dừng...');
    try {
      await _ffmpegHelper.cancelSession(); // Dừng FFmpeg
      await _youtubeService.stopLiveStream(); // Dừng broadcast
      setState(() {
        _isProcessing = false;
        _streamIsActive = false;
        _statusMessage = 'Sẵn sàng';
        _liveUrl = null;
      });
      _showSnackBar('Đã dừng phát trực tiếp');
    } catch (error) {
      _showSnackBar('Lỗi khi dừng: $error');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); // Hiển thị thông báo
  }

  @override
  void dispose() {
    _ffmpegHelper.cancelSession(); // Hủy FFmpeg khi widget bị hủy
    super.dispose(); // Gọi dispose của lớp cha
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Live Broadcast')), // Thanh tiêu đề
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_youtubeService.currentUser != null) ...[ // Nếu đã đăng nhập
                Text('Xin chào, $_userName!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Trạng thái: $_statusMessage'),
                if (_liveUrl != null) ...[
                  const SizedBox(height: 20),
                  const Text('Địa chỉ phát trực tiếp:'),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(
                      _liveUrl!,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _isProcessing
                    ? Column(
                  children: [
                    const CircularProgressIndicator(), // Hiển thị khi đang xử lý
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _stopLiveStream,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Dừng phát trực tiếp'),
                    ),
                  ],
                )
                    : ElevatedButton(
                  onPressed: _prepareLiveStream,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Chuẩn bị Livestream'),
                ),
                if (_streamIsActive) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startLiveStream,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Bắt đầu Livestream'),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleSignOut,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Đăng xuất'),
                ),
              ] else ...[ // Nếu chưa đăng nhập
                const Text('Vui lòng đăng nhập vào YouTube'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleSignIn,
                  child: const Text('Đăng nhập với Google'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}