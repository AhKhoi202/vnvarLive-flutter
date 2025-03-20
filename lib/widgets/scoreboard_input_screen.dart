// D:\AndroidStudioProjects\vnvar_flutter\lib\screens\scoreboard_input_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../controller/scoreboard_generator.dart';

class scoreboardInput extends StatefulWidget {
  final VoidCallback? onScoreboardUpdated; // Callback để thông báo cập nhật cho livestream

  const scoreboardInput({Key? key, this.onScoreboardUpdated}) : super(key: key);

  @override
  _scoreboardInputState createState() => _scoreboardInputState();
}

class _scoreboardInputState extends State<scoreboardInput> {
  TextEditingController player1Controller = TextEditingController(text: 'Player1');
  TextEditingController score1Controller = TextEditingController(text: '11');
  TextEditingController gameRulesController = TextEditingController(text: 'RATE TO 15');
  TextEditingController score2Controller = TextEditingController(text: '10');
  TextEditingController player2Controller = TextEditingController(text: 'Player2');
  String? imagePath;
  int _imageVersion = 0; // Biến để buộc reload hình ảnh

  @override
  void dispose() {
    player1Controller.dispose();
    score1Controller.dispose();
    gameRulesController.dispose();
    score2Controller.dispose();
    player2Controller.dispose();
    super.dispose();
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image(
              image: FileImage(File(imagePath)),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearImageCache(String path) async {
    await DefaultCacheManager().removeFile(path);
    PaintingBinding.instance.imageCache.clear(); // Xóa cache toàn bộ
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(0.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                TextField(
                  controller: player1Controller,
                  decoration: const InputDecoration(labelText: 'Người chơi 1'),
                ),
                TextField(
                  controller: score1Controller,
                  decoration: const InputDecoration(labelText: 'Tỷ số 1'),
                ),
                TextField(
                  controller: gameRulesController,
                  decoration: const InputDecoration(labelText: 'Luật chơi'),
                ),
                TextField(
                  controller: score2Controller,
                  decoration: const InputDecoration(labelText: 'Tỷ số 2'),
                ),
                TextField(
                  controller: player2Controller,
                  decoration: const InputDecoration(labelText: 'Người chơi 2'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final newImagePath = await ScoreboardGenerator.generateScoreboard(
                        player1: player1Controller.text,
                        score1: score1Controller.text,
                        gameRules: gameRulesController.text,
                        score2: score2Controller.text,
                        player2: player2Controller.text,
                      );

                      await Future.delayed(const Duration(milliseconds: 500));

                      if (!mounted) return;

                      if (imagePath != null) {
                        await _clearImageCache(imagePath!);
                      }

                      setState(() {
                        imagePath = newImagePath;
                        _imageVersion++; // Tăng version để buộc reload
                      });

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật tỷ số thành công!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      print('Ảnh mới đã được tạo tại: $imagePath với dữ liệu: ${player1Controller.text}, ${score1Controller.text}, ${gameRulesController.text}, ${score2Controller.text}, ${player2Controller.text}');
                      print('Kích thước file: ${await File(newImagePath).length()} bytes');

                      // Thông báo cho YouTubePlatform để cập nhật livestream
                      widget.onScoreboardUpdated?.call();
                    } catch (error) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi cập nhật: $error'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cập nhật tỷ số',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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