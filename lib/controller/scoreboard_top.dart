import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ScoreboardGenerator {

  // Thêm phương thức này vào lớp ScoreboardGenerator
  static Future<String> getScoreboardPath() async {
    // Lấy đường dẫn thư mục tạm
    final directory = await getTemporaryDirectory();
    return '${directory.path}/scoreboard.png';
  }

  static Future<String> generateScoreboard({
    required String player1,   // Cặp đấu 1 (format: "Anh Khoa / Trường An")
    required String score1,    // Điểm của cặp đấu 1
    required String player2,   // Cặp đấu 2 (format: "Phương / Quốc Thịnh")
    required String score2,    // Điểm của cặp đấu 2
    required String turn,  //Bên bóng (format: "A" hoặc "B")
    required String giao, // Lượt giao bóng (format: "Tay 1" hoặc "Tay 2")
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(1250, 200); // Kích thước bảng điểm mới
  // Xác định số bóng và đội đang giao
    print('Giá trị giao nhận vào: "$giao"');
    print('Độ dài chuỗi giao: ${giao.length}');
    print('Mã ASCII của từng ký tự trong chuỗi:');
    for (int i = 0; i < giao.length; i++) {
      print('Vị trí $i: ${giao.codeUnitAt(i)} - "${giao[i]}"');
    }
    final trimmedGiao = giao.trim();
    final numBalls = trimmedGiao.contains("1") ? 1 : 2;

    print('Sau khi trim: "${trimmedGiao}"');
    print('Số bóng được xác định: $numBalls');
    // Xác định đội nào đang giao bóng
    // - Nếu turn="A", bóng hiển thị ở hàng trên (team1Serving = true)
    // - Nếu turn="B", bóng hiển thị ở hàng dưới (team1Serving = false)
    final team1Serving = turn == "A";

    final shouldShowBalls = giao.trim().isNotEmpty;
    print('Có hiển thị bóng: $shouldShowBalls');

    await _buildScoreboard(
      player1: player1,
      score1: score1,
      player2: player2,
      score2: score2,
      team1Serving: team1Serving,
      numBalls: numBalls,
      showBalls: shouldShowBalls,
      canvas: canvas,
      size: size,
    );

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final imgImage = img.decodePng(pngBytes)!;
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/scoreboard.png';
    final file = File(filePath);

    // Thay đổi ở đây: trực tiếp ghi file mà không xóa file cũ
    print('Đang ghi đè lên file: $filePath');
    await file.writeAsBytes(img.encodePng(imgImage), flush: true);
    print('Hình ảnh mới đã được lưu tại: $filePath');

    if (await file.exists()) {
      print('File tồn tại, kích thước: ${await file.length()} bytes');
    } else {
      print('File không tồn tại!');
    }

    return filePath;
  }

  static Future<void> _buildScoreboard({
    required String player1,
    required String score1,
    required String player2,
    required String score2,
    required bool team1Serving,
    required int numBalls,
    required bool showBalls,
    required Canvas canvas,
    required Size size,
  }) async {
    final painter = ScoreboardPainter(
      player1: player1,
      score1: score1,
      player2: player2,
      score2: score2,
      team1Serving: team1Serving,
      numBalls: numBalls,
      showBalls: showBalls,
    );

    painter.paint(canvas, size);
  }
}

class ScoreboardPainter extends CustomPainter {
  final String player1;
  final String score1;
  final String player2;
  final String score2;
  final bool team1Serving;
  final int numBalls;
  final bool showBalls;

  ScoreboardPainter({
    required this.player1,
    required this.score1,
    required this.player2,
    required this.score2,
    required this.team1Serving,
    required this.numBalls,
    required this.showBalls,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final rowHeight = 100.0;

    // Vẽ nền chính với gradient và viền
    final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, rowHeight * 2),
        Radius.circular(16)
    );

    // Vẽ đổ bóng
    final shadowPaint = Paint()
      ..color = const Color(0x77001833)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16.0);
    canvas.drawRRect(bgRect, shadowPaint);

    // Vẽ nền gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(width * 0.6, 0),
        [
          const Color(0xFF0D1724),
          const Color(0xFF233A5E),
        ],
      );
    canvas.drawRRect(bgRect, bgPaint);

    // Vẽ viền
    final borderPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRRect(bgRect, borderPaint);

    // Vẽ hàng 1 (player1)
    _drawPlayerRow(
      canvas: canvas,
      playerName: player1,
      score: score1,
      isServing: team1Serving,
      numBalls: numBalls,
      y: 0,
      width: width,
      height: rowHeight,
      isTopRow: true,
    );

    // Vẽ hàng 2 (player2)
    _drawPlayerRow(
      canvas: canvas,
      playerName: player2,
      score: score2,
      isServing: !team1Serving,
      numBalls: numBalls,
      y: rowHeight,
      width: width,
      height: rowHeight,
      isTopRow: false,
    );
  }

  void _drawPlayerRow({
    required Canvas canvas,
    required String playerName,
    required String score,
    required bool isServing,
    required int numBalls,
    required double y,
    required double width,
    required double height,
    required bool isTopRow,
  }) {
    final scoreWidth = 150.0;
    final ballsWidth = 150.0;
    final nameWidth = width - scoreWidth - ballsWidth;

    // Vẽ tên cặp đấu
    _drawPlayerName(canvas, playerName, y, nameWidth, height);

    // Vẽ khu vực bóng giao
    if (showBalls && isServing) {
      _drawServeBalls(canvas, y, nameWidth, ballsWidth, height, numBalls);
    }

    // Vẽ điểm số
    _drawScore(canvas, score, y, nameWidth + ballsWidth, scoreWidth, height, isTopRow);
  }

  void _drawPlayerName(Canvas canvas, String playerName, double y, double width, double height) {
    final parts = playerName.split('/');
    final firstName = parts.isNotEmpty ? parts[0].trim() : playerName;
    final lastName = parts.length > 1 ? parts[1].trim() : '';

    final namePaint = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: firstName,
            style: const TextStyle(
              color: Color(0xFFE3EAF2),
              fontSize: 52,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Color(0x77000000),
                  offset: Offset(0, 2),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          if (lastName.isNotEmpty) TextSpan(
            text: ' / ',
            style: const TextStyle(
              color: Color(0xFFFFD600),
              fontSize: 60,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (lastName.isNotEmpty) TextSpan(
            text: lastName,
            style: const TextStyle(
              color: Color(0xFFE3EAF2),
              fontSize: 52,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Color(0x77000000),
                  offset: Offset(0, 2),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );

    namePaint.layout(maxWidth: width - 40);
    namePaint.paint(canvas, Offset(30, y + (height - namePaint.height) / 2));
  }

  void _drawServeBalls(Canvas canvas, double y, double x, double width, double height, int count) {
    // Không hiển thị nếu không có lượt giao
    if (!showBalls) return;

    final center = y + height / 2;
    final ballRadius = 32.0;

    final position2X = x + width - ballRadius * 2 - 20;

    // Bóng 1 (xa phần điểm số hơn)
    final position1X = x + width - (ballRadius * 2 * 2) - 20 - 24; // Cách bóng 2 một khoảng 24px

    // Luôn vẽ bóng 1 (nếu có giao bóng)
    _drawSingleBall(canvas, position1X, center, ballRadius);

    // Chỉ vẽ bóng 2 nếu count == 2
    if (count == 2) {
      _drawSingleBall(canvas, position2X, center, ballRadius);
    }
  }

// Hàm riêng để vẽ một quả bóng
  void _drawSingleBall(Canvas canvas, double startX, double center, double ballRadius) {
    // Vẽ bóng với gradient và viền
    final ballPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(startX + ballRadius * 0.65, center - ballRadius * 0.35),
        ballRadius * 2,
        [
          const Color(0xFFFFE066),
          const Color(0xFFFFD600),
        ],
        [0.75, 1.0],
      );

    canvas.drawCircle(Offset(startX + ballRadius, center), ballRadius, ballPaint);

    // Vẽ viền bóng
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(Offset(startX + ballRadius, center), ballRadius, borderPaint);

    // Vẽ chi tiết phản chiếu trên bóng
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFBE9);

    // Điểm trung tâm phản chiếu
    final centerX = startX + ballRadius;
    final centerY = center;

    // Vẽ 4 điểm phản chiếu
    canvas.drawCircle(Offset(centerX, centerY + 7), 3.5, highlightPaint);
    canvas.drawCircle(Offset(centerX + 7, centerY - 7), 3.5, highlightPaint);
    canvas.drawCircle(Offset(centerX, centerY), 3.5, highlightPaint);
    canvas.drawCircle(Offset(centerX - 7, centerY - 7), 3.5, highlightPaint);
  }
  void _drawScore(Canvas canvas, String score, double y, double x, double width, double height, bool isTopRow) {
    // Vẽ nền điểm với gradient
    final scoreRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(x, y, width, height),
      topRight: isTopRow ? const Radius.circular(10) : Radius.zero,
      bottomRight: !isTopRow ? const Radius.circular(10) : Radius.zero,
    );

    final scoreBgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y),
        Offset(0, y + height),
        [
          Colors.white,
          const Color(0xFFB3E0FF),
        ],
        [0.7, 1.0],
      );

    canvas.drawRRect(scoreRect, scoreBgPaint);

    // Vẽ số điểm
    final textPaint = TextPainter(
      text: TextSpan(
        text: score,
        style: const TextStyle(
          color: Color(0xFF17517E),
          fontSize: 52,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.white,
              offset: Offset(0, 2),
              blurRadius: 10,
            ),
            Shadow(
              color: Color(0xFFB3E0FF),
              offset: Offset(0, 1),
              blurRadius: 0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPaint.layout();
    final textX = x + (width - textPaint.width) / 2;
    final textY = y + (height - textPaint.height) / 2;
    textPaint.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}