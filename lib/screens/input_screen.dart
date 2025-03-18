import 'dart:io';
import 'package:flutter/material.dart';
import '../controller/scoreboard_generator.dart';

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  TextEditingController player1Controller = TextEditingController(text: 'Hoàng Sao');
  TextEditingController score1Controller = TextEditingController(text: '11');
  TextEditingController gameRulesController = TextEditingController(text: 'RATE TO 15');
  TextEditingController score2Controller = TextEditingController(text: '10');
  TextEditingController player2Controller = TextEditingController(text: 'Khải');
  String? imagePath; // Biến lưu đường dẫn ảnh

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nhập thông tin bảng tỷ số')),
      body: SingleChildScrollView( // Thêm để tránh tràn màn hình
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: player1Controller,
              decoration: InputDecoration(labelText: 'Người chơi 1'),
            ),
            TextField(
              controller: score1Controller,
              decoration: InputDecoration(labelText: 'Tỷ số 1'),
            ),
            TextField(
              controller: gameRulesController,
              decoration: InputDecoration(labelText: 'Luật chơi'),
            ),
            TextField(
              controller: score2Controller,
              decoration: InputDecoration(labelText: 'Tỷ số 2'),
            ),
            TextField(
              controller: player2Controller,
              decoration: InputDecoration(labelText: 'Người chơi 2'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Gọi hàm tạo ảnh và lấy đường dẫn
                imagePath = await ScoreboardGenerator.generateScoreboard(
                  player1: player1Controller.text,
                  score1: score1Controller.text,
                  gameRules: gameRulesController.text,
                  score2: score2Controller.text,
                  player2: player2Controller.text,
                );
                setState(() {}); // Cập nhật UI để hiển thị ảnh
              },
              child: Text('Tạo và hiển thị hình ảnh'),
            ),
            SizedBox(height: 20),
            // Hiển thị ảnh nếu imagePath không null
            if (imagePath != null)
              Image.file(
                File(imagePath!),
                width: 300, // Thu nhỏ để vừa màn hình
                fit: BoxFit.contain, // Giữ tỷ lệ ảnh
              ),
          ],
        ),
      ),
    );
  }
}