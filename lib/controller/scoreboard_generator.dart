// D:\AndroidStudioProjects\vnvar_flutter\lib\controller\scoreboard_generator.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ScoreboardGenerator {
  static Future<String> generateScoreboard({
    required String player1,
    required String score1,
    required String gameRules,
    required String score2,
    required String player2,
  }) async {
    final GlobalKey repaintKey = GlobalKey();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(2120, 100);

    await _buildScoreboard(repaintKey, player1, score1, gameRules, score2, player2, canvas, size);

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final imgImage = img.decodePng(pngBytes)!;
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/scoreboard.png';
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
      print('Đã xóa file cũ tại: $filePath');
    }

    await file.writeAsBytes(img.encodePng(imgImage), flush: true);
    print('Hình ảnh mới đã được lưu tại: $filePath');
    if (await file.exists()) {
      print('File tồn tại, kích thước: ${await file.length()} bytes');
    } else {
      print('File không tồn tại!');
    }

    return filePath;
  }

  static Future<void> _buildScoreboard(
      GlobalKey repaintKey,
      String player1,
      String score1,
      String gameRules,
      String score2,
      String player2,
      Canvas canvas,
      Size size,
      ) async {
    final painter = await _createScoreboardPainter(player1, score1, gameRules, score2, player2);
    painter.paint(canvas, size);
  }

  static Future<CustomPainter> _createScoreboardPainter(
      String player1,
      String score1,
      String gameRules,
      String score2,
      String player2,
      ) async {
    return ScoreboardPainter(
      player1: player1,
      score1: score1,
      gameRules: gameRules,
      score2: score2,
      player2: player2,
    );
  }
}

class ScoreboardPainter extends CustomPainter {
  final String player1;
  final String score1;
  final String gameRules;
  final String score2;
  final String player2;

  ScoreboardPainter({
    required this.player1,
    required this.score1,
    required this.gameRules,
    required this.score2,
    required this.player2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFF59A0D6);
    canvas.drawRect(Rect.fromLTWH(0, 0, 800, 100), paint1);
    _drawText(canvas, player1, 0, 800, 100);

    final paint2 = Paint()..color = const Color(0xFF17375E);
    canvas.drawRect(Rect.fromLTWH(800, 0, 100, 100), paint2);
    _drawText(canvas, score1, 800, 100, 100);

    final paint3 = Paint()..color = const Color(0xFF59A0D6);
    canvas.drawRect(Rect.fromLTWH(900, 0, 320, 100), paint3);
    _drawText(canvas, gameRules, 900, 320, 100);

    final paint4 = Paint()..color = const Color(0xFF17375E);
    canvas.drawRect(Rect.fromLTWH(1220, 0, 100, 100), paint4);
    _drawText(canvas, score2, 1220, 100, 100);

    final paint5 = Paint()..color = const Color(0xFF59A0D6);
    canvas.drawRect(Rect.fromLTWH(1320, 0, 800, 100), paint5);
    _drawText(canvas, player2, 1320, 800, 100);
  }

  void _drawText(Canvas canvas, String text, double x, double width, double height) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textX = x + (width - textPainter.width) / 2;
    final textY = (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}