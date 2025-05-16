// File: lib/screens/livestream_settings_screen.dart
// Mô tả: Màn hình cài đặt livestream, cho phép điều chỉnh hiển thị bảng điểm
// và chế độ nhập điểm thủ công

import 'package:flutter/material.dart';
import '../services/scoreboard_service.dart';
import '../widgets/scoreboard_input_screen.dart';

// Màn hình cài đặt cho tính năng livestream
// Cho phép bật/tắt hiển thị bảng điểm và thiết lập chế độ nhập điểm nhanh
class LivestreamSettingsScreen extends StatefulWidget {
  // Trạng thái hiển thị bảng điểm
  final bool isScoreboardVisible;

  // Callback khi thay đổi trạng thái hiển thị bảng điểm
  final Function(bool) onScoreboardVisibilityChanged;

  // Trạng thái chế độ nhập điểm thủ công
  final bool isManualScoreMode;

  // Callback khi thay đổi chế độ nhập điểm thủ công
  final Function(bool) onManualScoreModeChanged;

  const LivestreamSettingsScreen({
    Key? key,
    required this.isScoreboardVisible,
    required this.onScoreboardVisibilityChanged,
    this.isManualScoreMode = false,
    required this.onManualScoreModeChanged,
  }) : super(key: key);

  @override
  State<LivestreamSettingsScreen> createState() => _LivestreamSettingsScreenState();
}

class _LivestreamSettingsScreenState extends State<LivestreamSettingsScreen> {
  // Biến state để theo dõi trạng thái hiện tại
  late bool _isScoreboardVisible;
  late bool _isManualScoreMode;
  final ScoreboardService _scoreboardService = ScoreboardService();

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị từ props của widget
    _isScoreboardVisible = widget.isScoreboardVisible;
    _isManualScoreMode = widget.isManualScoreMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // Xây dựng AppBar với gradient
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 8,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF15273F), Color(0xFF0C3862)],
          ),
        ),
      ),
      title: const Text(
        'Cài đặt',
        style: TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // Xây dựng phần thân của màn hình với gradient
  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF104891), Color(0xFF107c90)],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Xây dựng khung cài đặt chính
  Widget _buildSettingsCard() {
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
          const Text(
            'Cài đặt Livestream',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Cài đặt hiển thị bảng điểm
          _buildVisibilityToggle(),
          // Hiển thị các tùy chọn khác nếu bảng điểm được bật
          if (_isScoreboardVisible) ...[
            // Cài đặt chế độ nhập điểm thủ công
            _buildManualModeToggle(),
            // Hiển thị bảng điểm
            const SizedBox(height: 16),
            ScoreboardInput(),
          ],
        ],
      ),
    );
  }

  // Xây dựng công tắc bật/tắt bảng điểm
  Widget _buildVisibilityToggle() {
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

  // Xây dựng công tắc bật/tắt chế độ nhập điểm thủ công
  Widget _buildManualModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Hiển thị nút tăng/giảm điểm',
          style: TextStyle(fontSize: 16),
        ),
        Switch(
          value: _isManualScoreMode,
          onChanged: (value) {
            setState(() {
              _isManualScoreMode = value;
              // Cập nhật trạng thái useManualInput của ScoreboardService
              _scoreboardService.useManualInput = value;
            });
            widget.onManualScoreModeChanged(value);
          },
          activeColor: const Color(0xFF346ED7),
        ),
      ],
    );
  }
}