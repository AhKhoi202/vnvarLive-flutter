// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\scoreboard_input_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../controller/scoreboard_top.dart';
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
  // Thêm controllers cố định cho IP và table
  late TextEditingController ipController;
  late TextEditingController tableController;

  String? imagePath; // Đường dẫn đến file scoreboard.png
  int _imageVersion = 0; // Biến để buộc reload hình ảnh khi thay đổi
  Timer? _timer; // Timer để tự động gọi API
  final ScoreboardService _scoreboardService = ScoreboardService(); // Instance của service gọi API
  String? _ip; // Lưu địa chỉ IP từ dialog
  String? _table; // Lưu tên bàn từ dialog
  bool _useManualInput = false; // Cờ kiểm soát: true = dùng nhập tay, false = dùng API
  bool _isFirstConfirmation = true; // Cờ để kiểm tra lần xác nhận đầu tiên
  String gameType = 'Đánh đơn'; // State for game type
  String? _turn; // Lưu thông tin lượt (A or B)
  String? _giao; // Lưu thông tin người giao
  bool _dataChanged = false; // Biến theo dõi thay đổi dữ liệu
  bool _autoUpdateStarted = false; // Cờ theo dõi việc tự động cập nhật đã bắt đầu chưa

  @override
  void initState() {
    super.initState();
    _ip = '192.168.1.44';  // Khởi tạo giá trị mặc định
    _table = 'pickleball';  // Khởi tạo giá trị mặc định

    // Khởi tạo controllers với giá trị
    ipController = TextEditingController(text: _ip);
    tableController = TextEditingController(text: _table);

    // Không tự động khởi động timer nữa
    // _startAutoUpdate();
  }

  @override
  void reassemble() {
    super.reassemble();
    print("Hot reload detected");
    // Chỉ khởi động lại timer nếu đã bắt đầu tự động trước đó
    if (_autoUpdateStarted) {
      _startAutoUpdate();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy timer để tránh rò rỉ bộ nhớ
    player1Controller.dispose(); // Giải phóng các controller
    score1Controller.dispose();
    gameRulesController.dispose();
    score2Controller.dispose();
    player2Controller.dispose();
    ipController.dispose();
    tableController.dispose();
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
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  // Hàm xóa cache hình ảnh để đảm bảo load ảnh mới
  Future<void> _clearImageCache(String path) async {
    try {
      await DefaultCacheManager().removeFile(path); // Xóa file khỏi cache của flutter_cache_manager
      await Future.delayed(const Duration(milliseconds: 100)); // Đợi xóa file hoàn tất
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      print('Lỗi khi xóa cache: $e');
    }
  }
  // Hàm gọi API để lấy điểm số tự động
  Future<void> _fetchScoreFromApi({bool startAutoUpdate = false}) async {
    // Kiểm tra điều kiện để gọi API
    if (_ip == null || _ip!.isEmpty) {
      _ip = ipController.text;
    }
    if (_table == null || _table!.isEmpty) {
      _table = tableController.text;
    }

    // Phần code còn lại giữ nguyên
    if (_useManualInput) {
      return;
    }

    try {
      final scores = await _scoreboardService.fetchScore(_ip!, _table!);
      print("scores: $scores");
      if (scores != null && mounted) { // Kiểm tra nếu API trả về dữ liệu
        // Kiểm tra xem dữ liệu có thay đổi không
        bool changed = false;

        if (score1Controller.text != scores['score_a']?.toString() ||
            score2Controller.text != scores['score_b']?.toString() ||
            _turn != scores['turn']?.toString() ||
            _giao != scores['giao']?.toString()) {
          changed = true;
        }

        // Kiểm tra và cập nhật điểm
        setState(() {
          // Cập nhật điểm nếu có
          score1Controller.text = scores.containsKey('score_a') ? scores['score_a'].toString() : '';
          score2Controller.text = scores.containsKey('score_b') ? scores['score_b'].toString() : '';
          // Thêm đoạn lưu giá trị turn và giao từ API
          _turn = scores.containsKey('turn') ? scores['turn'].toString() : null;
          _giao = scores.containsKey('giao') ? scores['giao'].toString() : null;
          // Xác định kiểu chơi và cập nhật tên người chơi
          if (scores.containsKey('name_a2') && scores['name_a2'].toString().trim().isNotEmpty) {
            // Trận đánh đôi
            gameType = 'Đánh đôi';

            // Cập nhật tên đội A
            final nameA1 = scores.containsKey('name_a1') ? scores['name_a1'].toString().trim() : ''; // Kiểm tra tên thứ 1
            final nameA2 = scores['name_a2'].toString().trim(); // Kiểm tra tên thứ 2
            player1Controller.text = nameA1.isNotEmpty && nameA2.isNotEmpty
                ? '$nameA1 / $nameA2' : nameA1.isNotEmpty ? nameA1 : nameA2;

            // Cập nhật tên đội B
            final nameB1 = scores.containsKey('name_b1') ? scores['name_b1'].toString().trim() : '';
            final nameB2 = scores.containsKey('name_b2') ? scores['name_b2'].toString().trim() : '';
            player2Controller.text = nameB1.isNotEmpty && nameB2.isNotEmpty
                ? '$nameB1 / $nameB2' : nameB1.isNotEmpty ? nameB1 : nameB2;

          }
          else {
            // Trận đánh đơn
            gameType = 'Đánh đơn';
            player1Controller.text = scores.containsKey('name_a1') ? scores['name_a1'].toString().trim() : ''; // Kiểm tra tên thứ 1
            player2Controller.text = scores.containsKey('name_b1') ? scores['name_b1'].toString().trim() : ''; // Kiểm tra tên thứ 1
          }
          _dataChanged = changed; // Đánh dấu dữ liệu thay đổi
          print('Dữ liệu đã thay đổi: $changed');
        });

        // Chỉ cập nhật hình ảnh nếu dữ liệu thay đổi hoặc không có hình ảnh
        if (changed || imagePath == null) {
          await _updateScoreboard(isManual: false, showSuccess: true);
        }

        // Nếu đây là lần đầu gọi và yêu cầu bắt đầu tự động cập nhật
        if (startAutoUpdate && !_autoUpdateStarted) {
          _autoUpdateStarted = true;
          _startAutoUpdate();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã bắt đầu tự động cập nhật mỗi 3 giây'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          print('API trả về dữ liệu rỗng hoặc lỗi');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API trả về dữ liệu rỗng, vui lòng kiểm tra kết nối'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        print('Lỗi khi gọi API: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối đến API: $error'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
        score2: score2Controller.text,
        player2: player2Controller.text,
        turn: _turn ?? "",
        giao: _giao ?? "",
      );

      await Future.delayed(const Duration(milliseconds: 500)); // Đợi file được ghi hoàn tất
      if (!mounted) return; // Thoát nếu widget bị hủy
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
      print('Ảnh mới: $imagePath - ${player1Controller.text}, ${score1Controller.text}, ${score2Controller.text}, ${player2Controller.text}');
      print('Kích thước file: ${await File(newImagePath).length()} bytes');

      widget.onScoreboardUpdated?.call(); // Thông báo cho livestream để restart luồng
    } catch (error) {
      if (!mounted) return;
      print('Lỗi khi cập nhật bảng điểm: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật bảng điểm: $error')),
      );
    }
  }

  // Hàm khởi động tự động cập nhật từ API
  void _startAutoUpdate() {
    _timer?.cancel(); // Hủy timer cũ nếu có
    if (_ip != null && _table != null && !_useManualInput) {
      print('Bắt đầu lập lịch timer tự động 3s');
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        print('Timer tự động kích hoạt lần ${timer.tick}');
        print('Khởi động timer, IP: $_ip, table: $_table, useManualInput: $_useManualInput');
        _fetchScoreFromApi();
      });
    } else {
      print('Không khởi động timer do điều kiện không thỏa: IP=$_ip, table=$_table, useManual=$_useManualInput');
    }
  }

  // Giao diện chính của widget
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(0.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                // Replace the RadioListTile widgets with Row and Switch widgets
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nguồn dữ liệu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sử dụng điểm từ máy trạm',
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: !_useManualInput,
                            onChanged: (value) {
                              setState(() {
                                _useManualInput = !value;
                                if (_useManualInput) {
                                  // Hủy timer khi chuyển sang chế độ nhập tay
                                  _timer?.cancel();
                                  _autoUpdateStarted = false;
                                }
                                // Không tự động khởi động timer khi chuyển sang chế độ máy trạm
                              });
                            },
                            activeColor: const Color(0xFF346ED7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nhập điểm thủ công',
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: _useManualInput,
                            onChanged: (value) {
                              setState(() {
                                _useManualInput = value;
                                if (_useManualInput) {
                                  // Hủy timer khi chuyển sang chế độ nhập tay
                                  _timer?.cancel();
                                  _autoUpdateStarted = false;
                                }
                                // Không tự động khởi động timer khi chuyển sang chế độ máy trạm
                              });
                            },
                            activeColor: const Color(0xFF346ED7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hiển thị trường nhập thông tin máy trạm
                if (!_useManualInput)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: 'Địa chỉ IP máy trạm'),
                        controller: ipController,
                        onChanged: (val) {
                          _ip = val;
                          // Không gọi _startAutoUpdate() nữa, đợi người dùng nhấn nút
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Tên bàn'),
                        controller: tableController,
                        onChanged: (val) {
                          _table = val;
                          // Không gọi _startAutoUpdate() nữa, đợi người dùng nhấn nút
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Gọi API và bắt đầu tự động cập nhật
                          _fetchScoreFromApi(startAutoUpdate: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          _autoUpdateStarted ? 'Cập nhật lại điểm số' : 'Lấy điểm từ máy trạm',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      if (_autoUpdateStarted)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Đang tự động cập nhật mỗi 3 giây',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),

                // Hiển thị các trường nhập điểm thủ công
                if (_useManualInput)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: gameType,
                        decoration: const InputDecoration(labelText: 'Kiểu chơi'),
                        items: const [
                          DropdownMenuItem(value: 'Đánh đơn', child: Text('Đánh đơn')),
                          DropdownMenuItem(value: 'Đánh đôi', child: Text('Đánh đôi')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              gameType = value;
                            });
                          }
                        },
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
                        controller: player2Controller,
                        decoration: const InputDecoration(labelText: 'Người chơi 2'),
                      ),
                      TextField(
                        controller: score2Controller,
                        decoration: const InputDecoration(labelText: 'Tỷ số 2'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _updateScoreboard(isManual: true),
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
                    onTap: () => _showImageDialog(imagePath!),
                    child: Image.file(
                      File(imagePath!),
                      width: 300,
                      fit: BoxFit.contain,
                      key: ValueKey(_imageVersion),
                      gaplessPlayback: false, // Đảm bảo không giữ hình ảnh cũ khi load ảnh mới
                    ),
                  )
                else
                  const Text('Chưa có ảnh bảng điểm'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}