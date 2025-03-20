// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\scoreboard_input_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../controller/scoreboard_generator.dart';
import '../services/scoreboard_service.dart';

// Widget chính đại diện cho giao diện nhập bảng điểm
class ScoreboardInput extends StatefulWidget {
  final VoidCallback? onScoreboardUpdated; // Callback để thông báo cập nhật cho livestream

  const ScoreboardInput({Key? key, this.onScoreboardUpdated}) : super(key: key);

  @override
  _ScoreboardInputState createState() => _ScoreboardInputState();
}

class _ScoreboardInputState extends State<ScoreboardInput> {
  // Các controller để quản lý dữ liệu nhập từ TextField
  TextEditingController player1Controller = TextEditingController(text: 'Player1');
  TextEditingController score1Controller = TextEditingController(text: '0');
  TextEditingController gameRulesController = TextEditingController(text: 'RATE TO 15');
  TextEditingController score2Controller = TextEditingController(text: '0');
  TextEditingController player2Controller = TextEditingController(text: 'Player2');
  String? imagePath; // Đường dẫn đến file scoreboard.png
  int _imageVersion = 0; // Biến để buộc reload hình ảnh khi thay đổi
  Timer? _timer; // Timer để tự động gọi API
  final ScoreboardService _scoreboardService = ScoreboardService(); // Instance của service gọi API
  String? _ip; // Lưu địa chỉ IP từ dialog
  String? _table; // Lưu tên bàn từ dialog
  bool _useManualInput = false; // Cờ kiểm soát: true = dùng nhập tay, false = dùng API
  bool _isFirstConfirmation = true; // Cờ để kiểm tra lần xác nhận đầu tiên

  @override
  void initState() {
    super.initState();
    _startAutoUpdate(); // Khởi động timer tự động cập nhật khi màn hình được tạo
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy timer để tránh rò rỉ bộ nhớ
    player1Controller.dispose(); // Giải phóng các controller
    score1Controller.dispose();
    gameRulesController.dispose();
    score2Controller.dispose();
    player2Controller.dispose();
    super.dispose();
  }

  // Hàm hiển thị dialog xem trước hình ảnh bảng điểm
  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // Đóng dialog khi nhấn vào ảnh
            child: Image(
              image: FileImage(File(imagePath)),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  // Hàm xóa cache hình ảnh để đảm bảo load ảnh mới
  Future<void> _clearImageCache(String path) async {
    await DefaultCacheManager().removeFile(path); // Xóa file khỏi cache của flutter_cache_manager
    PaintingBinding.instance.imageCache.clear(); // Xóa cache hình ảnh của Flutter
  }

  // Hàm hiển thị dialog để nhập thông tin bàn (IP và tên bàn)
  void _showTableInfoDialog() {
    final ipController = TextEditingController(text: _ip ?? '192.168.1.44'); // Giá trị mặc định cho IP
    final tableController = TextEditingController(text: _table ?? 'pickleball'); // Giá trị mặc định cho tên bàn

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhập thông tin bàn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(labelText: 'Địa chỉ máy trạm (IP)'),
            ),
            TextField(
              controller: tableController,
              decoration: const InputDecoration(labelText: 'Tên bàn (Table)'),
            ),
          ],
        ),
        actions: [
          // Nút "Không sử dụng" để hủy việc dùng API
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Đóng dialog ngay khi nhấn nút
              setState(() {
                _useManualInput = true; // Chuyển sang chế độ nhập tay
                _ip = null; // Xóa thông tin IP
                _table = null; // Xóa thông tin bàn
                _isFirstConfirmation = true; // Reset cờ xác nhận đầu tiên
              });
              _timer?.cancel(); // Dừng timer tự động cập nhật
            },
            child: const Text('Không sử dụng'),
          ),
          // Nút "Xác nhận" để lưu thông tin và kiểm tra API
          TextButton(
            onPressed: () async {
              if (ipController.text.isNotEmpty && tableController.text.isNotEmpty) {
                // Kiểm tra cả hai trường đều được nhập
                Navigator.pop(dialogContext); // Đóng dialog ngay khi nhấn nút
                setState(() {
                  _ip = ipController.text; // Lưu IP
                  _table = tableController.text; // Lưu tên bàn
                  _useManualInput = false; // Reset về chế độ dùng API
                });

                // Kiểm tra API ngay lập tức sau khi đóng dialog
                final scores = await _scoreboardService.fetchScore(_ip!, _table!);
                if (scores != null && mounted) {
                  // Nếu API hợp lệ
                  setState(() {
                    score1Controller.text = scores['score_a'].toString(); // Cập nhật điểm từ API
                    score2Controller.text = scores['score_b'].toString();
                  });
                  _startAutoUpdate(); // Bắt đầu tự động cập nhật mỗi 10 giây
                  await _updateScoreboard(isManual: false, showSuccess: _isFirstConfirmation); // Thông báo lần đầu nếu thành công
                  _isFirstConfirmation = false; // Đặt lại cờ sau lần đầu xác nhận thành công
                } else {
                  // Nếu API lỗi hoặc không có dữ liệu
                  setState(() {
                    _useManualInput = true; // Chuyển sang chế độ nhập tay
                    _isFirstConfirmation = true; // Reset cờ nếu lỗi
                  });
                  _timer?.cancel(); // Dừng timer ngay lập tức
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API lỗi hoặc không có dữ liệu, sử dụng điểm nhập tay'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                // Nếu thiếu IP hoặc tên bàn, không đóng dialog mà hiển thị thông báo
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập cả IP và tên bàn')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // Hàm gọi API để lấy điểm số tự động
  Future<void> _fetchScoreFromApi() async {
    // Kiểm tra điều kiện để gọi API
    if (_ip == null || _table == null || _useManualInput) return; // Không gọi nếu thiếu thông tin hoặc đang dùng nhập tay

    final scores = await _scoreboardService.fetchScore(_ip!, _table!);
    if (scores != null && mounted) {
      // Nếu API trả về dữ liệu hợp lệ
      setState(() {
        score1Controller.text = scores['score_a'].toString(); // Cập nhật điểm từ API
        score2Controller.text = scores['score_b'].toString();
      });
      await _updateScoreboard(isManual: false, showSuccess: false); // Không thông báo trong cập nhật tự động
    } else {
      // Nếu API lỗi hoặc không có dữ liệu
      setState(() {
        _useManualInput = true; // Chuyển sang chế độ nhập tay
        _isFirstConfirmation = true; // Reset cờ nếu lỗi
      });
      _timer?.cancel(); // Dừng timer ngay lập tức
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API lỗi hoặc không có dữ liệu, sử dụng điểm nhập tay'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Hàm cập nhật bảng điểm và tạo file scoreboard.png
  Future<void> _updateScoreboard({bool isManual = true, bool showSuccess = true}) async {
    // isManual = true khi cập nhật thủ công, false khi từ API
    // showSuccess = true khi muốn hiển thị thông báo thành công, false khi không
    try {
      final newImagePath = await ScoreboardGenerator.generateScoreboard(
        player1: player1Controller.text,
        score1: score1Controller.text,
        gameRules: gameRulesController.text,
        score2: score2Controller.text,
        player2: player2Controller.text,
      );

      await Future.delayed(const Duration(milliseconds: 500)); // Đợi file được ghi hoàn tất

      if (!mounted) return; // Thoát nếu widget bị hủy

      if (imagePath != null) {
        await _clearImageCache(imagePath!); // Xóa cache ảnh cũ
      }

      setState(() {
        imagePath = newImagePath; // Cập nhật đường dẫn ảnh mới
        _imageVersion++; // Tăng version để buộc reload ảnh
      });

      if (!mounted) return;

      // Hiển thị thông báo thành công khi cập nhật thủ công hoặc lần đầu xác nhận API thành công
      if ((isManual || (!isManual && showSuccess)) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật bảng điểm thành công!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Log thông tin để debug
      print('Ảnh mới: $imagePath - ${player1Controller.text}, ${score1Controller.text}, ${gameRulesController.text}, ${score2Controller.text}, ${player2Controller.text}');
      print('Kích thước file: ${await File(newImagePath).length()} bytes');

      widget.onScoreboardUpdated?.call(); // Thông báo cho livestream để restart luồng
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật bảng điểm: $error')),
      );
    }
  }

  // Hàm khởi động tự động cập nhật từ API
  void _startAutoUpdate() {
    _timer?.cancel(); // Hủy timer cũ nếu có
    if (_ip != null && _table != null && !_useManualInput) {
      // Chỉ chạy timer nếu có thông tin bàn và đang dùng API
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        // Gọi API mỗi 10 giây
        _fetchScoreFromApi();
      });
    }
  }

  // Giao diện chính của widget
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Tắt cuộn riêng của ScoreboardInput
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(0.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                // Nút để mở dialog nhập thông tin bàn
                ElevatedButton(
                  onPressed: _showTableInfoDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Sử dụng điểm từ bàn',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: player1Controller,
                  decoration: const InputDecoration(labelText: 'Người chơi 1'),
                ),
                TextField(
                  controller: score1Controller,
                  decoration: const InputDecoration(labelText: 'Tỷ số 1'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: gameRulesController,
                  decoration: const InputDecoration(labelText: 'Luật chơi'),
                ),
                TextField(
                  controller: score2Controller,
                  decoration: const InputDecoration(labelText: 'Tỷ số 2'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: player2Controller,
                  decoration: const InputDecoration(labelText: 'Người chơi 2'),
                ),
                const SizedBox(height: 20),
                // Nút cập nhật thủ công
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateScoreboard(isManual: true), // Gọi với isManual = true để thông báo
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Cập nhật bảng điểm',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Hiển thị ảnh bảng điểm nếu có
                if (imagePath != null)
                  GestureDetector(
                    onTap: () => _showImageDialog(imagePath!), // Mở dialog xem ảnh khi nhấn
                    child: Image(
                      image: FileImage(File(imagePath!), scale: 1.0),
                      width: 300,
                      fit: BoxFit.contain,
                      key: ValueKey(_imageVersion), // Đảm bảo ảnh reload khi version thay đổi
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}