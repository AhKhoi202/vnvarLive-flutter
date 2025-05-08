// lib/screens/livestream_settings_screen.dart
import 'package:flutter/material.dart';
import '../widgets/scoreboard_input_screen.dart';

class LivestreamSettingsScreen extends StatefulWidget {
  final bool isScoreboardVisible;
  final Function(bool) onScoreboardVisibilityChanged;

  const LivestreamSettingsScreen({
    Key? key,
    required this.isScoreboardVisible,
    required this.onScoreboardVisibilityChanged,
  }) : super(key: key);

  @override
  State<LivestreamSettingsScreen> createState() => _LivestreamSettingsScreenState();
}


class _LivestreamSettingsScreenState extends State<LivestreamSettingsScreen> {
  late bool _isScoreboardVisible;

  @override
  void initState() {
    super.initState();
    _isScoreboardVisible = widget.isScoreboardVisible;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: Container(
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
                      'Cài đặt Livestream',
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
                          'Hiện bảng tỷ số',
                          style: TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: _isScoreboardVisible,
                          onChanged: (value) {
                            setState(() {
                              _isScoreboardVisible = value;
                            });
                            print('_isScoreboardVisible_setting: $value');
                            widget.onScoreboardVisibilityChanged(value);
                          },
                          activeColor: const Color(0xFF346ED7),
                        ),
                      ],
                    ),
                    // Thêm hiển thị ScoreboardInput có điều kiện tại đây
                    if (_isScoreboardVisible) ...[
                      const SizedBox(height: 16),
                      ScoreboardInput(),
                    ],
                    // Có thể thêm các tùy chọn khác ở đây
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}