// D:\AndroidStudioProjects\vnvar_flutter\lib\widgets\scoreboard_input_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/scoreboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm import này


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
  TextEditingController score2Controller = TextEditingController(text: '0');
  TextEditingController player2Controller = TextEditingController(text: 'Player2');
  // Controllers cho IP và table
  late TextEditingController ipController;
  late TextEditingController tableController;

  // Biến trạng thái
  String? imagePath; // Đường dẫn đến file scoreboard.png
  int _imageVersion = 0; // Biến để buộc reload hình ảnh khi thay đổi
  final ScoreboardService _scoreboardService = ScoreboardService(); // Singleton service
  String? _ip; // Lưu địa chỉ IP từ dialog
  String? _table; // Lưu tên bàn từ dialog
  bool _useManualInput = false; // Cờ kiểm soát: true = dùng nhập tay, false = dùng API
  String gameType = 'Đánh đơn'; // Kiểu trận đấu
  String? _turn; // Lưu thông tin lượt (A or B)
  String? _giao; // Lưu thông tin người giao
  bool _autoUpdateStarted = false; // Cờ theo dõi việc tự động cập nhật đã bắt đầu chưa

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị mặc định
    _ip = '192.168.1.44';
    _table = 'pickleball';
    // Đọc cài đặt đã lưu
    _loadSavedSettings();
    // Đăng ký callback từ service để cập nhật UI
    _scoreboardService.onDataChanged = _updateUIFromService;

    // Đăng ký callback cho cập nhật scoreboard
    _scoreboardService.onScoreboardUpdated = () {
      widget.onScoreboardUpdated?.call();
      _loadImagePath(); // Cập nhật đường dẫn hình ảnh
    };

    // Kiểm tra nếu service đang chạy
    if (_scoreboardService.isRunning) {
      _autoUpdateStarted = true;
      _useManualInput = _scoreboardService.useManualInput;

      // Lấy dữ liệu từ service để cập nhật UI
      _updateUIFromService();
    }

    // Khởi tạo controllers với giá trị
    ipController = TextEditingController(text: _ip);
    tableController = TextEditingController(text: _table);

    // Đăng ký callback từ service để cập nhật UI
    _scoreboardService.onDataChanged = _updateUIFromService;

    // Đăng ký callback cho cập nhật scoreboard
    _scoreboardService.onScoreboardUpdated = () {
      widget.onScoreboardUpdated?.call();
      _loadImagePath(); // Cập nhật đường dẫn hình ảnh
    };

    // Kiểm tra nếu service đang chạy
    if (_scoreboardService.isRunning) {
      _autoUpdateStarted = true;
      _useManualInput = _scoreboardService.useManualInput;

      // Lấy dữ liệu từ service để cập nhật UI
      _updateUIFromService();
    }
  }

  // Tải cài đặt đã lưu từ SharedPreferences
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Đọc các giá trị đã lưu hoặc sử dụng giá trị mặc định
    setState(() {
      _ip = prefs.getString('scoreboard_ip') ?? '192.168.1.44';
      _table = prefs.getString('scoreboard_table') ?? 'pickleball';
      _useManualInput = prefs.getBool('scoreboard_manual_input') ?? false;

      // Cập nhật controllers sau khi đọc giá trị
      ipController = TextEditingController(text: _ip);
      tableController = TextEditingController(text: _table);
    });

    // Cập nhật service với giá trị cũ nếu đã lưu
    final wasAutoUpdateRunning = prefs.getBool('scoreboard_auto_update_running') ?? false;
    if (wasAutoUpdateRunning && !_useManualInput) {
      _fetchScoreFromApi();
    }

    print('Đã tải cài đặt đã lưu: IP=$_ip, Bàn=$_table, Thủ công=$_useManualInput');
  }

  // Lưu cài đặt vào SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('scoreboard_ip', ipController.text);
    await prefs.setString('scoreboard_table', tableController.text);
    await prefs.setBool('scoreboard_manual_input', _useManualInput);
    await prefs.setBool('scoreboard_auto_update_running', _autoUpdateStarted);

    print('Đã lưu cài đặt: IP=${ipController.text}, Bàn=${tableController.text}, Thủ công=$_useManualInput');
  }
  // Cập nhật UI từ dữ liệu trong service
  void _updateUIFromService() {
    if (!mounted) return;

    setState(() {
      // Cập nhật thông tin người chơi và điểm số
      player1Controller.text = _scoreboardService.player1;
      player2Controller.text = _scoreboardService.player2;
      score1Controller.text = _scoreboardService.score1;
      score2Controller.text = _scoreboardService.score2;

      // Cập nhật các thông tin khác
      gameType = _scoreboardService.gameType;
      _turn = _scoreboardService.turn;
      _giao = _scoreboardService.giao;
    });

    // Tải hình ảnh mới nếu có
    _loadImagePath();
  }

  // Tải đường dẫn hình ảnh mới nhất
  Future<void> _loadImagePath() async {
    try {
      String? path;
      if (_scoreboardService.imagePath != null) {
        path = _scoreboardService.imagePath;
      } else {
        path = await ScoreboardService.getScoreboardPath();
      }

      if (path != null && await File(path).exists()) {
        if (mounted) {
          setState(() {
            imagePath = path;
            _imageVersion++; // Tăng version để buộc reload ảnh
          });
        }
      }
    } catch (e) {
      print('Lỗi khi tải hình ảnh: $e');
    }
  }

  @override
  void dispose() {
    // Giải phóng controllers
    player1Controller.dispose();
    score1Controller.dispose();
    score2Controller.dispose();
    player2Controller.dispose();
    ipController.dispose();
    tableController.dispose();

    // QUAN TRỌNG: KHÔNG hủy timer trong service để nó tiếp tục chạy

    super.dispose();
  }

  // Hiển thị dialog xem chi tiết hình ảnh
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

  // Xóa cache hình ảnh để đảm bảo load ảnh mới
  Future<void> _clearImageCache(String path) async {
    try {
      await DefaultCacheManager().removeFile(path);
      await Future.delayed(const Duration(milliseconds: 100));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      print('Lỗi khi xóa cache: $e');
    }
  }

  // Gọi API để lấy điểm số và bắt đầu tự động cập nhật
  Future<void> _fetchScoreFromApi() async {
    // Lấy thông tin IP và tên bàn từ controllers
    final ip = ipController.text;
    final table = tableController.text;

    if (ip.isEmpty || table.isEmpty) {
      _showSnackBar('Vui lòng nhập địa chỉ IP và tên bàn');
      return;
    }

    try {
      // Bắt đầu cập nhật tự động qua service
      _scoreboardService.startAutoUpdate(ip, table);

      // Cập nhật trạng thái UI
      setState(() {
        _useManualInput = false;
        _autoUpdateStarted = true;
        _ip = ip;
        _table = table;
      });
      _saveSettings();
      _showSnackBar('Đã bắt đầu tự động cập nhật mỗi 3 giây');

      // Không cần đợi timer đầu tiên, hình ảnh sẽ được cập nhật qua callback
    } catch (error) {
      _showSnackBar('Lỗi khi kết nối: $error');
    }
  }

  // Cập nhật bảng điểm thủ công
  Future<void> _updateScoreboard() async {
    try {
      // Đánh dấu đang sử dụng chế độ nhập thủ công
      _scoreboardService.useManualInput = true;

      // Cập nhật dữ liệu từ controllers vào service
      final newImagePath = await _scoreboardService.updateManualData(
        player1Value: player1Controller.text,
        score1Value: score1Controller.text,
        score2Value: score2Controller.text,
        player2Value: player2Controller.text,
        gameTypeValue: gameType,
        turnValue: _turn,
        giaoValue: _giao,
      );

      if (newImagePath != null) {
        setState(() {
          imagePath = newImagePath;
          _imageVersion++; // Tăng version để buộc reload ảnh
        });
        _saveSettings();
        _showSnackBar('Cập nhật bảng điểm thành công!');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Lỗi khi cập nhật bảng điểm: $error');
    }
  }

  // Hiển thị thông báo
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2))
      );
    }
  }

  // Dừng tự động cập nhật
  void _stopAutoUpdate() {
    _scoreboardService.stopAutoUpdate();
    setState(() {
      _autoUpdateStarted = false;
    });
    // Lưu trạng thái
    _saveSettings();
    _showSnackBar('Đã dừng tự động cập nhật');
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
            delegate: SliverChildListDelegate([
              // Chọn nguồn dữ liệu
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
                              // Cập nhật trạng thái trong service
                              _scoreboardService.useManualInput = _useManualInput;
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
                              // Cập nhật trạng thái trong service
                              _scoreboardService.useManualInput = value;
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

              // Nhập thông tin máy trạm
              if (!_useManualInput)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Địa chỉ IP máy trạm'),
                      controller: ipController,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Tên bàn'),
                      controller: tableController,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _autoUpdateStarted
                          ? ElevatedButton(
                        onPressed: _stopAutoUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Dừng cập nhật',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: _fetchScoreFromApi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Lấy điểm từ máy trạm',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
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

              // Nhập điểm thủ công
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
                      onPressed: _updateScoreboard,
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

              // Hiển thị bảng điểm
              if (imagePath != null)
                GestureDetector(
                  onTap: () => _showImageDialog(imagePath!),
                  child: Image.file(
                    File(imagePath!),
                    width: 300,
                    fit: BoxFit.contain,
                    key: ValueKey(_imageVersion), // Key để đảm bảo reload khi dữ liệu thay đổi
                    gaplessPlayback: false,
                  ),
                )
              else
                const Text('Chưa có ảnh bảng điểm'),
            ]),
          ),
        ),
      ],
    );
  }
}