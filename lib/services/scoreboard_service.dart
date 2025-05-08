import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../controller/scoreboard_top.dart';

class ScoreboardService {
  // Singleton pattern để đảm bảo chỉ có một instance trong toàn bộ ứng dụng
  static final ScoreboardService _instance = ScoreboardService._internal();
  factory ScoreboardService() => _instance;
  ScoreboardService._internal();

  // Biến state và timer
  Timer? _timer;
  String? _ip;
  String? _table;
  bool _isRunning = false;
  bool _useManualInput = false;

  // Biến lưu dữ liệu
  Map<String, dynamic> _lastScoreData = {};

  // Dữ liệu hiện tại
  String _player1 = 'Player1';
  String _player2 = 'Player2';
  String _score1 = '0';
  String _score2 = '0';
  String? _turn;
  String? _giao;
  String _gameType = 'Đánh đơn';
  String? _imagePath;

  // Callbacks
  VoidCallback? onDataChanged;
  VoidCallback? onScoreboardUpdated;

  // Getters
  bool get isRunning => _isRunning;
  String? get ip => _ip;
  String? get table => _table;
  bool get useManualInput => _useManualInput;
  String get player1 => _player1;
  String get player2 => _player2;
  String get score1 => _score1;
  String get score2 => _score2;
  String? get turn => _turn;
  String? get giao => _giao;
  String get gameType => _gameType;
  String? get imagePath => _imagePath;

  // Setters
  set useManualInput(bool value) {
    _useManualInput = value;
    if (value) {
      // Không tự động hủy timer khi chuyển sang chế độ nhập thủ công
    }
  }

  // Phương thức gọi API lấy điểm số
  Future<Map<String, dynamic>?> fetchScore(String ip, String table) async {
    final url = Uri.parse('http://$ip/home/getscore?tb=$table');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          // Xử lý các giá trị chuỗi
          data.forEach((key, value) {
            if (value is String) {
              data[key] = value.trim();
            }
          });
          return data;
        } else {
          print('Dữ liệu API không hợp lệ: $data');
          return null;
        }
      } else {
        print('API trả về lỗi: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Lỗi khi gọi API: $error');
      return null;
    }
  }

  // Bắt đầu cập nhật tự động
  void startAutoUpdate(String ip, String table) {
    _ip = ip;
    _table = table;
    _useManualInput = false;
  print('Bắt đầu tự động cập nhật với IP: $ip, bàn: $table, _useManualInput: $_useManualInput');
    if (_isRunning) {
      stopAutoUpdate();
    }
    _isRunning = true;

    // Khởi tạo timer cập nhật mỗi 3 giây
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchAndUpdateScore();
    });
    print('Đã bắt đầu tự động cập nhật 3s');

    // Lấy dữ liệu ngay lập tức không đợi timer đầu tiên
    _fetchAndUpdateScore();
  }

  // Dừng cập nhật tự động
  void stopAutoUpdate() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    print('Đã dừng tự động cập nhật');
  }

  // Gọi API và xử lý dữ liệu
  Future<void> _fetchAndUpdateScore() async {
    if (_useManualInput || _ip == null || _table == null) return;
  print('Đang tự động cập nhật dữ liệu từ API...');
    try {
      final scores = await fetchScore(_ip!, _table!);
      if (scores != null) {
        // Kiểm tra dữ liệu có thay đổi không
        bool dataChanged = _hasDataChanged(scores);

        // Cập nhật dữ liệu mới
        _lastScoreData = Map.from(scores);
        _score1 = scores['score_a']?.toString() ?? '0';
        _score2 = scores['score_b']?.toString() ?? '0';
        _turn = scores['turn']?.toString();
        _giao = scores['giao']?.toString();

        // Cập nhật tên người chơi
        if (scores.containsKey('name_a2') && scores['name_a2'].toString().isNotEmpty) {
          _gameType = 'Đánh đôi';
          final nameA1 = scores.containsKey('name_a1') ? scores['name_a1'].toString() : '';
          final nameA2 = scores['name_a2'].toString();
          _player1 = nameA1.isNotEmpty && nameA2.isNotEmpty
              ? '$nameA1 / $nameA2' : nameA1.isNotEmpty ? nameA1 : nameA2;

          final nameB1 = scores.containsKey('name_b1') ? scores['name_b1'].toString() : '';
          final nameB2 = scores.containsKey('name_b2') ? scores['name_b2'].toString() : '';
          _player2 = nameB1.isNotEmpty && nameB2.isNotEmpty
              ? '$nameB1 / $nameB2' : nameB1.isNotEmpty ? nameB1 : nameB2;
        } else {
          _gameType = 'Đánh đơn';
          _player1 = scores.containsKey('name_a1') ? scores['name_a1'].toString() : '';
          _player2 = scores.containsKey('name_b1') ? scores['name_b1'].toString() : '';
        }

        // Thông báo UI khi dữ liệu thay đổi
        if (dataChanged) {
          // Cập nhật hình ảnh
          await updateScoreboard();

          // Thông báo cho listeners
          onDataChanged?.call();
        }
      }
    } catch (e) {
      print('Lỗi khi tự động cập nhật: $e');
    }
  }

  // So sánh dữ liệu cũ và mới
  bool _hasDataChanged(Map<String, dynamic> newData) {
    if (_lastScoreData.isEmpty) return true;

    // So sánh các trường quan trọng
    if (_lastScoreData['score_a']?.toString() != newData['score_a']?.toString() ||
        _lastScoreData['score_b']?.toString() != newData['score_b']?.toString() ||
        _lastScoreData['turn']?.toString() != newData['turn']?.toString() ||
        _lastScoreData['giao']?.toString() != newData['giao']?.toString()) {
      return true;
    }

    // So sánh tên người chơi
    for (final key in ['name_a1', 'name_a2', 'name_b1', 'name_b2']) {
      if (_lastScoreData[key]?.toString() != newData[key]?.toString()) {
        return true;
      }
    }

    return false;
  }

  // Cập nhật hình ảnh bảng điểm
  Future<String?> updateScoreboard() async {
    try {
      final newImagePath = await ScoreboardGenerator.generateScoreboard(
        player1: _player1,
        score1: _score1,
        score2: _score2,
        player2: _player2,
        turn: _turn ?? "",
        giao: _giao ?? "",
      );

      _imagePath = newImagePath;

      // Thông báo cho các listeners rằng hình ảnh đã được cập nhật
      onScoreboardUpdated?.call();

      return newImagePath;
    } catch (e) {
      print('Lỗi khi cập nhật hình ảnh: $e');
      return null;
    }
  }

  // Cập nhật dữ liệu thủ công từ người dùng
  Future<String?> updateManualData({
    String? player1Value,
    String? score1Value,
    String? score2Value,
    String? player2Value,
    String? gameTypeValue,
    String? turnValue,
    String? giaoValue,
  }) async {
    // Cập nhật các giá trị
    if (player1Value != null) _player1 = player1Value;
    if (score1Value != null) _score1 = score1Value;
    if (score2Value != null) _score2 = score2Value;
    if (player2Value != null) _player2 = player2Value;
    if (gameTypeValue != null) _gameType = gameTypeValue;
    if (turnValue != null) _turn = turnValue;
    if (giaoValue != null) _giao = giaoValue;

    return await updateScoreboard();
  }

  // Lấy đường dẫn file hiện tại
  static Future<String> getScoreboardPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/scoreboard.png';
  }
}

// Thêm kiểu dữ liệu VoidCallback để đơn giản hóa code
typedef VoidCallback = void Function();