// File: scoreboard_overlay.dart
// Mô tả: Widget hiển thị bảng điểm nổi trên giao diện live stream,
// hỗ trợ chế độ nhập điểm nhanh với các nút tăng/giảm điểm

import 'package:flutter/material.dart';
import '../services/scoreboard_service.dart';
import 'dart:developer' as developer;

// Widget hiển thị bảng điểm nổi trên giao diện
// Cho phép xem điểm số và thay đổi điểm nhanh chóng khi ở chế độ thủ công
class ScoreboardOverlay extends StatefulWidget {
  // Xác định xem có đang ở chế độ nhập điểm thủ công hay không
  final bool isManualMode;

  const ScoreboardOverlay({
    Key? key,
    this.isManualMode = false,
  }) : super(key: key);

  @override
  State<ScoreboardOverlay> createState() => _ScoreboardOverlayState();
}

class _ScoreboardOverlayState extends State<ScoreboardOverlay> {
  //---------------------------
  // PROPERTIES
  //---------------------------
  final ScoreboardService _scoreboardService = ScoreboardService();
  VoidCallback? _dataSourceListener;

  // Hiển thị các điều khiển tăng giảm điểm khi đang ở chế độ thủ công
  bool get _shouldShowControls =>
      widget.isManualMode && _scoreboardService.useManualInput;

  //---------------------------
  // LIFECYCLE METHODS
  //---------------------------
  @override
  void initState() {
    super.initState();
    _registerListeners();
  }

  // Đăng ký các listeners để cập nhật UI khi dữ liệu thay đổi
  void _registerListeners() {
    // Cập nhật khi dữ liệu điểm số thay đổi
    _scoreboardService.onDataChanged = () {
      if (mounted) setState(() {});
    };

    // Cập nhật khi hình ảnh bảng điểm thay đổi
    _scoreboardService.onScoreboardUpdated = () {
      if (mounted) setState(() {});
    };

    // Theo dõi thay đổi nguồn dữ liệu (nhập thủ công/máy trạm)
    _dataSourceListener = () {
      if (mounted) setState(() {});
    };
    _scoreboardService.onDataSourceChanged = _dataSourceListener;
  }

  @override
  void dispose() {
    // Hủy đăng ký tất cả listeners
    _scoreboardService.onDataChanged = null;
    _scoreboardService.onScoreboardUpdated = null;
    _scoreboardService.onDataSourceChanged = null;
    super.dispose();
  }

  //---------------------------
  // UI BUILDING
  //---------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTeamNames(),
          const SizedBox(height: 10),
          _buildScoreControls(),
        ],
      ),
    );
  }

  // Hiển thị tên của các đội/người chơi
  Widget _buildTeamNames() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildPlayerName(_scoreboardService.player1),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'vs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: _buildPlayerName(_scoreboardService.player2),
        ),
      ],
    );
  }

  // Hiển thị tên người chơi với định dạng
  Widget _buildPlayerName(String name) {
    return Text(
      name,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Hiển thị điểm số và các nút điều khiển
  Widget _buildScoreControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Điểm số đội 1 với các nút điều khiển
        _buildScoreControlGroup(
          score: _scoreboardService.score1,
          onIncrement: _incrementScore1,
          onDecrement: _decrementScore1,
          color: Colors.blue,
        ),

        const SizedBox(width: 20),

        // Điểm số đội 2 với các nút điều khiển
        _buildScoreControlGroup(
          score: _scoreboardService.score2,
          onIncrement: _incrementScore2,
          onDecrement: _decrementScore2,
          color: Colors.red,
        ),
      ],
    );
  }

  // Nhóm điều khiển điểm số cho một đội
  Widget _buildScoreControlGroup({
    required String score,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required Color color,
  }) {
    return Row(
      children: [
        // Nút giảm điểm
        if (_shouldShowControls)
          _buildControlButton(
            icon: Icons.remove,
            onPressed: onDecrement,
            color: Colors.red.withOpacity(0.7),
          ),

        if (_shouldShowControls) const SizedBox(width: 8),

        // Hiển thị điểm
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            score,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),

        // Nút tăng điểm
        if (_shouldShowControls) const SizedBox(width: 8),
        if (_shouldShowControls)
          _buildControlButton(
            icon: Icons.add,
            onPressed: onIncrement,
            color: Colors.green.withOpacity(0.7),
          ),
      ],
    );
  }

  // Tạo nút điều khiển tăng/giảm điểm
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 24,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
      ),
    );
  }

  //---------------------------
  // SCORE MANIPULATION
  //---------------------------

  // Tăng điểm cho đội 1
  void _incrementScore1() {
    int score = int.tryParse(_scoreboardService.score1) ?? 0;
    score++;
    _updateScore(score.toString(), _scoreboardService.score2);
  }

  // Giảm điểm cho đội 1
  void _decrementScore1() {
    int score = int.tryParse(_scoreboardService.score1) ?? 0;
    if (score > 0) score--;
    _updateScore(score.toString(), _scoreboardService.score2);
  }

  // Tăng điểm cho đội 2
  void _incrementScore2() {
    int score = int.tryParse(_scoreboardService.score2) ?? 0;
    score++;
    _updateScore(_scoreboardService.score1, score.toString());
  }

  // Giảm điểm cho đội 2
  void _decrementScore2() {
    int score = int.tryParse(_scoreboardService.score2) ?? 0;
    if (score > 0) score--;
    _updateScore(_scoreboardService.score1, score.toString());
  }

  // Cập nhật điểm số vào service và làm mới UI
  Future<void> _updateScore(String score1, String score2) async {
    // Đảm bảo đang ở chế độ nhập thủ công
    _scoreboardService.useManualInput = true;

    // Cập nhật điểm số vào service
    await _scoreboardService.updateManualData(
      score1Value: score1,
      score2Value: score2,
    );

    // Làm mới UI
    if (mounted) setState(() {});
  }
}