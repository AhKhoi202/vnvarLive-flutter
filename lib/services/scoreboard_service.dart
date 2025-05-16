// File: scoreboard_service.dart
// Mô tả: Service quản lý dữ liệu bảng điểm, hỗ trợ cả cập nhật tự động từ API và nhập liệu thủ công

import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../controller/scoreboard_top.dart';

// Các kiểu callback được sử dụng trong service
typedef VoidCallback = void Function();
typedef ErrorCallback = void Function(String errorMessage, bool stoppedUpdating);

// Service quản lý dữ liệu bảng điểm
// Thiết kế theo Singleton pattern để đảm bảo duy nhất trong toàn ứng dụng
class ScoreboardService {
  //---------------------------
  // SINGLETON PATTERN
  //---------------------------
  static final ScoreboardService _instance = ScoreboardService._internal();
  factory ScoreboardService() => _instance;
  ScoreboardService._internal();

  //---------------------------
  // PROPERTIES & CONSTANTS
  //---------------------------

  // Cài đặt và cấu hình
  static const int MAX_ERROR_COUNT = 3; // Số lần lỗi tối đa trước khi dừng
  Timer? _timer;                        // Timer định kỳ gọi API
  String? _ip;                          // Địa chỉ IP máy trạm
  String? _table;                       // Tên bàn
  bool _isRunning = false;              // Trạng thái cập nhật tự động
  bool _useManualInput = false;         // True: nhập thủ công, False: từ API
  int _errorCount = 0;                  // Đếm số lần lỗi liên tiếp

  // Dữ liệu bảng điểm
  Map<String, dynamic> _lastScoreData = {}; // Lưu dữ liệu API gần nhất để so sánh
  String _player1 = 'Player1';             // Tên người chơi 1
  String _player2 = 'Player2';             // Tên người chơi 2
  String _score1 = '0';                    // Điểm số 1
  String _score2 = '0';                    // Điểm số 2
  String? _turn;                           // Lượt đánh (A hoặc B)
  String? _giao;                           // Người giao bóng
  String _gameType = 'Đánh đơn';           // Loại trận đấu (đơn hoặc đôi)
  String? _imagePath;                      // Đường dẫn đến file ảnh bảng điểm

  // Callbacks để thông báo cho UI
  VoidCallback? onDataChanged;            // Khi dữ liệu thay đổi
  VoidCallback? onScoreboardUpdated;      // Khi bảng điểm được cập nhật
  VoidCallback? onDataSourceChanged;       // Khi nguồn dữ liệu thay đổi
  ErrorCallback? onApiError;              // Khi có lỗi API

  //---------------------------
  // GETTERS & SETTERS
  //---------------------------

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
    if (_useManualInput != value) {
      _useManualInput = value;
      onDataSourceChanged?.call();
    }
  }

  //---------------------------
  // API INTERACTION
  //---------------------------

  // Gọi API để lấy dữ liệu điểm số từ máy trạm
  Future<Map<String, dynamic>?> fetchScore(String ip, String table) async {
    final url = Uri.parse('http://$ip/home/getscore?tb=$table');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          // Làm sạch dữ liệu (loại bỏ khoảng trắng thừa)
          data.forEach((key, value) {
            if (value is String) {
              data[key] = value.trim();
            }
          });
          _errorCount = 0; // Reset bộ đếm lỗi khi thành công
          return data;
        } else {
          _handleApiError('Dữ liệu API không hợp lệ');
          return null;
        }
      } else {
        _handleApiError('Máy trạm báo lỗi: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      _handleApiError('Không thể kết nối đến máy trạm');
      return null;
    }
  }

  // Xử lý lỗi API và quyết định có nên dừng cập nhật hay không
  void _handleApiError(String errorMessage) {
    _errorCount++;

    bool shouldStopUpdating = _errorCount >= MAX_ERROR_COUNT;

    // Gọi callback để thông báo lỗi cho UI
    onApiError?.call(errorMessage, shouldStopUpdating);

    // Dừng cập nhật nếu số lỗi vượt ngưỡng
    if (shouldStopUpdating) {
      stopAutoUpdate();
    }
  }

  //---------------------------
  // AUTO UPDATE CONTROL
  //---------------------------

  // Bắt đầu cập nhật tự động từ API
  void startAutoUpdate(String ip, String table) {
    _ip = ip;
    _table = table;
    _useManualInput = false;
    _errorCount = 0; // Reset bộ đếm lỗi

    // Hủy timer cũ nếu đang chạy
    if (_isRunning) {
      stopAutoUpdate();
    }

    _isRunning = true;

    // Khởi tạo timer cập nhật mỗi 3 giây
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchAndUpdateScore();
    });

    // Lấy dữ liệu ngay lập tức không đợi timer
    _fetchAndUpdateScore();
  }

  // Dừng cập nhật tự động
  void stopAutoUpdate() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
    }
  }

  // Gọi API và xử lý dữ liệu
  Future<void> _fetchAndUpdateScore() async {
    // Kiểm tra điều kiện trước khi thực hiện
    if (_useManualInput || _ip == null || _table == null || !_isRunning) return;

    try {
      final scores = await fetchScore(_ip!, _table!);
      if (scores != null) {
        // Chỉ cập nhật UI khi dữ liệu thay đổi
        bool dataChanged = _hasDataChanged(scores);

        // Lưu dữ liệu mới
        _lastScoreData = Map.from(scores);

        // Cập nhật các giá trị cơ bản
        _updateDataFromApiResponse(scores);

        // Thông báo UI khi dữ liệu thay đổi
        if (dataChanged) {
          await updateScoreboard();  // Tạo hình ảnh bảng điểm mới
          onDataChanged?.call();     // Thông báo UI cập nhật
        }
      }
    } catch (e) {
      _handleApiError('Lỗi khi cập nhật: ${e.toString().substring(0, math.min(e.toString().length, 100))}');
    }
  }

  // Cập nhật dữ liệu nội bộ từ phản hồi API
  void _updateDataFromApiResponse(Map<String, dynamic> scores) {
    // Cập nhật điểm số và trạng thái
    _score1 = scores['score_a']?.toString() ?? '0';
    _score2 = scores['score_b']?.toString() ?? '0';
    _turn = scores['turn']?.toString();
    _giao = scores['giao']?.toString();

    // Cập nhật thông tin người chơi dựa trên kiểu trận đấu
    if (scores.containsKey('name_a2') && scores['name_a2'].toString().isNotEmpty) {
      // Trận đấu đôi
      _gameType = 'Đánh đôi';
      _updateDoublesPlayerNames(scores);
    } else {
      // Trận đấu đơn
      _gameType = 'Đánh đơn';
      _player1 = scores.containsKey('name_a1') ? scores['name_a1'].toString() : '';
      _player2 = scores.containsKey('name_b1') ? scores['name_b1'].toString() : '';
    }
  }

  // Cập nhật tên cặp đôi từ dữ liệu API
  void _updateDoublesPlayerNames(Map<String, dynamic> scores) {
    final nameA1 = scores.containsKey('name_a1') ? scores['name_a1'].toString() : '';
    final nameA2 = scores['name_a2'].toString();
    _player1 = nameA1.isNotEmpty && nameA2.isNotEmpty
        ? '$nameA1 / $nameA2' : nameA1.isNotEmpty ? nameA1 : nameA2;

    final nameB1 = scores.containsKey('name_b1') ? scores['name_b1'].toString() : '';
    final nameB2 = scores.containsKey('name_b2') ? scores['name_b2'].toString() : '';
    _player2 = nameB1.isNotEmpty && nameB2.isNotEmpty
        ? '$nameB1 / $nameB2' : nameB1.isNotEmpty ? nameB1 : nameB2;
  }

  // So sánh dữ liệu cũ và mới để xác định có thay đổi không
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

  //---------------------------
  // SCOREBOARD GENERATION
  //---------------------------

  // Tạo hình ảnh bảng điểm mới từ dữ liệu hiện tại
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

      // Thông báo cho UI rằng hình ảnh đã được cập nhật
      onScoreboardUpdated?.call();
      return newImagePath;
    } catch (e) {
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
    bool hasChanges = false;

    // Cập nhật các giá trị nếu được cung cấp
    if (player1Value != null) {
      _player1 = player1Value;
      hasChanges = true;
    }
    if (score1Value != null) {
      _score1 = score1Value;
      hasChanges = true;
    }
    if (score2Value != null) {
      _score2 = score2Value;
      hasChanges = true;
    }
    if (player2Value != null) {
      _player2 = player2Value;
      hasChanges = true;
    }
    if (gameTypeValue != null) _gameType = gameTypeValue;
    if (turnValue != null) _turn = turnValue;
    if (giaoValue != null) _giao = giaoValue;

    // Thông báo UI về thay đổi dữ liệu
    if (hasChanges) {
      onDataChanged?.call();
    }

    // Tạo hình ảnh bảng điểm mới
    final result = await updateScoreboard();

    // Đảm bảo UI được cập nhật sau khi tạo scoreboard
    if (hasChanges) {
      Future.delayed(Duration(milliseconds: 100), () {
        onDataChanged?.call();
      });
    }

    return result;
  }

  // Lấy đường dẫn file bảng điểm
  static Future<String> getScoreboardPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/scoreboard.png';
  }
}