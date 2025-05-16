// File: scoreboard_input_screen.dart
// Mô tả: Widget cho phép nhập và hiển thị bảng điểm trong ứng dụng.
// Hỗ trợ hai chế độ: nhập điểm thủ công hoặc tự động lấy từ máy trạm qua API.

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/scoreboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget cho phép nhập và hiển thị thông tin bảng điểm
// Cung cấp giao diện cho người dùng nhập liệu và xem trước bảng điểm
class ScoreboardInput extends StatefulWidget {
  // Callback được gọi khi bảng điểm được cập nhật, thông báo cho livestream
  final VoidCallback? onScoreboardUpdated;

  // Xác định chế độ nhập điểm thủ công, cho phép sử dụng nút +/- để thay đổi điểm
  final bool? isManualScoreMode;

  const ScoreboardInput({Key? key, this.onScoreboardUpdated, this.isManualScoreMode}) : super(key: key);

  @override
  _ScoreboardInputState createState() => _ScoreboardInputState();
}

class _ScoreboardInputState extends State<ScoreboardInput> {
  //---------------------------
  // CONTROLLER & BIẾN TRẠNG THÁI
  //---------------------------

  // Controllers cho các trường nhập liệu của người chơi và điểm số
  final TextEditingController player1Controller = TextEditingController(text: 'Player1');
  final TextEditingController score1Controller = TextEditingController(text: '0');
  final TextEditingController score2Controller = TextEditingController(text: '0');
  final TextEditingController player2Controller = TextEditingController(text: 'Player2');
  late TextEditingController ipController;      // Địa chỉ IP của máy trạm
  late TextEditingController tableController;   // Tên bàn đấu

  // Service xử lý logic bảng điểm và tương tác API
  final ScoreboardService _scoreboardService = ScoreboardService();

  // Đường dẫn đến hình ảnh bảng điểm
  String? imagePath;

  // Số phiên bản của hình ảnh, dùng để buộc reload khi dữ liệu thay đổi
  int _imageVersion = 0;

  // Thông tin cấu hình kết nối
  String? _ip = '192.168.1.44';       // IP mặc định
  String? _table = 'pickleball';      // Tên bàn mặc định

  // Cờ điều khiển chế độ nhập liệu
  bool _useManualInput = false;       // false: lấy từ API, true: nhập thủ công
  bool _autoUpdateStarted = false;    // theo dõi trạng thái cập nhật tự động

  // Thông tin trận đấu
  String gameType = 'Đánh đơn';       // Kiểu chơi: đơn hoặc đôi
  String? _turn;                      // Lượt đánh (A hoặc B)
  String? _giao;                      // Người giao bóng

  // Trả về trạng thái chế độ nhập điểm thủ công từ widget cha
  bool get _isManualScoreMode => widget.isManualScoreMode ?? false;

  //---------------------------
  // VÒNG ĐỜI WIDGET
  //---------------------------

  @override
  void initState() {
    super.initState();
    _setupControllers();       // Thiết lập controllers
    _loadSavedSettings();      // Tải cài đặt đã lưu
    _registerCallbacks();      // Đăng ký các callbacks
  }

  // Khởi tạo controllers với giá trị mặc định
  void _setupControllers() {
    ipController = TextEditingController(text: _ip);
    tableController = TextEditingController(text: _table);
  }

  // Đăng ký các callbacks để xử lý sự kiện từ service
  void _registerCallbacks() {
    // Callback khi dữ liệu thay đổi
    _scoreboardService.onDataChanged = _updateUIFromService;

    // Callback khi bảng điểm được cập nhật
    _scoreboardService.onScoreboardUpdated = () {
      widget.onScoreboardUpdated?.call();  // Thông báo cho widget cha
      _loadImagePath();                    // Tải lại đường dẫn hình ảnh
    };

    // Callback khi có lỗi API
    _scoreboardService.onApiError = _handleApiError;

    // Khôi phục trạng thái nếu service đang chạy
    if (_scoreboardService.isRunning) {
      _autoUpdateStarted = true;
      _useManualInput = _scoreboardService.useManualInput;
      _updateUIFromService();  // Cập nhật UI từ dữ liệu trong service
    }
  }

  @override
  void dispose() {
    // Giải phóng tài nguyên controllers
    player1Controller.dispose();
    score1Controller.dispose();
    score2Controller.dispose();
    player2Controller.dispose();
    ipController.dispose();
    tableController.dispose();

    // QUAN TRỌNG: KHÔNG hủy timer trong service để nó tiếp tục chạy
    super.dispose();
  }

  //---------------------------
  // QUẢN LÝ CÀI ĐẶT
  //---------------------------

  // Tải các cài đặt đã lưu từ SharedPreferences
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Đọc các giá trị đã lưu hoặc sử dụng giá trị mặc định
      _ip = prefs.getString('scoreboard_ip') ?? '192.168.1.44';
      _table = prefs.getString('scoreboard_table') ?? 'pickleball';
      _useManualInput = prefs.getBool('scoreboard_manual_input') ?? false;

      // Cập nhật controllers
      ipController.text = _ip!;
      tableController.text = _table!;
    });

    // Khôi phục trạng thái cập nhật tự động nếu đã bật trước đó
    final wasAutoUpdateRunning = prefs.getBool('scoreboard_auto_update_running') ?? false;
    if (wasAutoUpdateRunning && !_useManualInput) {
      _fetchScoreFromApi();  // Bắt đầu lại quá trình cập nhật tự động
    }
  }

  // Lưu các cài đặt vào SharedPreferences để khôi phục sau khi khởi động lại
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scoreboard_ip', ipController.text);
    await prefs.setString('scoreboard_table', tableController.text);
    await prefs.setBool('scoreboard_manual_input', _useManualInput);
    await prefs.setBool('scoreboard_auto_update_running', _autoUpdateStarted);
  }

  //---------------------------
  // CẬP NHẬT UI
  //---------------------------

  // Cập nhật giao diện từ dữ liệu trong service
  void _updateUIFromService() {
    if (!mounted) return;  // Kiểm tra widget còn trong cây widget không

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

    _loadImagePath();  // Tải lại đường dẫn hình ảnh
  }

  // Tải đường dẫn hình ảnh mới nhất
  Future<void> _loadImagePath() async {
    try {
      // Lấy đường dẫn từ service hoặc gọi phương thức tĩnh
      String? path = _scoreboardService.imagePath ?? await ScoreboardService.getScoreboardPath();

      // Kiểm tra xem file có tồn tại không
      if (path != null && await File(path).exists()) {
        if (mounted) {
          setState(() {
            imagePath = path;
            _imageVersion++;  // Tăng version để buộc reload ảnh
          });
        }
      }
    } catch (e) {
      print('Lỗi khi tải hình ảnh: $e');
    }
  }

  //---------------------------
  // TƯƠNG TÁC API
  //---------------------------

  // Gọi API để lấy điểm số và bắt đầu tự động cập nhật
  Future<void> _fetchScoreFromApi() async {
    final ip = ipController.text;
    final table = tableController.text;

    // Kiểm tra tính hợp lệ của dữ liệu đầu vào
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

      _saveSettings();  // Lưu cài đặt
      _showSnackBar('Đã bắt đầu tự động cập nhật mỗi 3 giây');
    } catch (error) {
      _showSnackBar('Lỗi khi kết nối: $error');
    }
  }

  // Dừng quá trình tự động cập nhật từ API
  void _stopAutoUpdate() {
    _scoreboardService.stopAutoUpdate();
    setState(() {
      _autoUpdateStarted = false;
    });
    _saveSettings();  // Lưu trạng thái
    _showSnackBar('Đã dừng tự động cập nhật');
  }

  //---------------------------
  // CẬP NHẬT THỦ CÔNG
  //---------------------------

  // Cập nhật bảng điểm với dữ liệu nhập thủ công
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

      // Cập nhật UI nếu có đường dẫn hình ảnh mới
      if (newImagePath != null) {
        setState(() {
          imagePath = newImagePath;
          _imageVersion++;  // Tăng version để buộc reload ảnh
        });
        _saveSettings();
        _showSnackBar('Cập nhật bảng điểm thành công!');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Lỗi khi cập nhật bảng điểm: $error');
    }
  }

  //---------------------------
  // XỬ LÝ LỖI
  //---------------------------

  // Xử lý lỗi từ API và hiển thị thông báo
  void _handleApiError(String errorMessage, bool stoppedUpdating) {
    if (!mounted) return;

    // Tùy chỉnh thông báo dựa trên mức độ nghiêm trọng
    String message = stoppedUpdating
        ? "⚠️ $errorMessage\n➡️ Đã tự động dừng cập nhật từ máy trạm!"
        : "⚠️ $errorMessage";

    // Hiển thị thông báo lỗi
    _showSnackBar(message, duration: stoppedUpdating ? 5 : 2);

    // Cập nhật UI nếu đã dừng cập nhật
    if (stoppedUpdating) {
      setState(() {
        _autoUpdateStarted = false;
      });
      _saveSettings();  // Lưu trạng thái
    }
  }

  // Hiển thị thông báo dạng SnackBar
  void _showSnackBar(String message, {int duration = 2}) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: duration),
          )
      );
    }
  }

  // Hiển thị dialog xem chi tiết hình ảnh
  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),  // Đóng dialog khi nhấn vào ảnh
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  //---------------------------
  // THÀNH PHẦN UI
  //---------------------------

  // Hiển thị thông báo về chức năng nhập điểm nhanh
  Widget _buildQuickScoreInputNotice() {
    if (!_useManualInput) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bạn có thể tăng/giảm điểm trực tiếp bằng cách nhấn các nút + và - trên màn hình xem trước.',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Xây dựng phần chọn nguồn dữ liệu (API hoặc thủ công)
  Widget _buildDataSourceSelector() {
    return Container(
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
          const Text('Nguồn dữ liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Switch cho điểm từ máy trạm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sử dụng điểm từ máy trạm', style: TextStyle(fontSize: 16)),
              Switch(
                value: !_useManualInput,
                onChanged: (value) {
                  setState(() {
                    _useManualInput = !value;
                    _scoreboardService.useManualInput = _useManualInput;
                  });
                  _saveSettings();
                },
                activeColor: const Color(0xFF346ED7),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Switch cho nhập điểm thủ công
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nhập điểm thủ công', style: TextStyle(fontSize: 16)),
              Switch(
                value: _useManualInput,
                onChanged: (value) {
                  setState(() {
                    _useManualInput = value;
                    _scoreboardService.useManualInput = value;
                  });
                  _saveSettings();
                },
                activeColor: const Color(0xFF346ED7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Xây dựng phần nhập thông tin kết nối API
  Widget _buildApiInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Các trường nhập IP và tên bàn
        TextField(
          decoration: const InputDecoration(labelText: 'Địa chỉ IP máy trạm'),
          controller: ipController,
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Tên bàn'),
          controller: tableController,
        ),
        const SizedBox(height: 16),
        // Nút điều khiển cập nhật
        Center(
          child: _autoUpdateStarted
              ? ElevatedButton(
            onPressed: _stopAutoUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Dừng cập nhật', style: TextStyle(color: Colors.white, fontSize: 16)),
          )
              : ElevatedButton(
            onPressed: _fetchScoreFromApi,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lấy điểm từ máy trạm', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        // Thông báo trạng thái cập nhật
        if (_autoUpdateStarted)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Đang tự động cập nhật mỗi 3 giây',
              style: TextStyle(color: Colors.green.shade700, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  // Xây dựng phần nhập điểm thủ công
  Widget _buildManualInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chọn kiểu chơi (đơn hoặc đôi)
        DropdownButtonFormField<String>(
          value: gameType,
          decoration: const InputDecoration(labelText: 'Kiểu chơi'),
          items: const [
            DropdownMenuItem(value: 'Đánh đơn', child: Text('Đánh đơn')),
            DropdownMenuItem(value: 'Đánh đôi', child: Text('Đánh đôi')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => gameType = value);
            }
          },
        ),
        const SizedBox(height: 10),
        // Trường nhập thông tin người chơi
        TextField(
          controller: player1Controller,
          decoration: const InputDecoration(labelText: 'Người chơi 1'),
        ),
        TextField(
          controller: player2Controller,
          decoration: const InputDecoration(labelText: 'Người chơi 2'),
        ),
        const SizedBox(height: 16),
        // Nút cập nhật bảng điểm
        ElevatedButton(
          onPressed: _updateScoreboard,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cập nhật bảng điểm', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }

  // Xây dựng phần xem trước bảng điểm
  Widget _buildScoreboardPreview() {
    // Hiển thị thông báo nếu chưa có hình ảnh
    if (imagePath == null) return const Text('Chưa có ảnh bảng điểm');
    // Hiển thị hình ảnh với khả năng phóng to xem chi tiết
    return GestureDetector(
      onTap: () => _showImageDialog(imagePath!),  // Hiển thị hình ảnh phóng to khi nhấp vào
      child: Image.file(
        File(imagePath!),
        width: 300,
        fit: BoxFit.contain,
        key: ValueKey(_imageVersion),  // Key để buộc reload khi cập nhật
        gaplessPlayback: false,
      ),
    );
  }

  // Xây dựng giao diện chính của widget
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
              _buildQuickScoreInputNotice(),       // Thông báo nhập điểm nhanh
              _buildDataSourceSelector(),          // Chọn nguồn dữ liệu
              const SizedBox(height: 16),
              if (!_useManualInput) _buildApiInputSection(),     // Phần API nếu dùng máy trạm
              if (_useManualInput) _buildManualInputSection(),   // Phần nhập thủ công nếu chọn
              const SizedBox(height: 20),
              _buildScoreboardPreview(),           // Xem trước bảng điểm
            ]),
          ),
        ),
      ],
    );
  }
}