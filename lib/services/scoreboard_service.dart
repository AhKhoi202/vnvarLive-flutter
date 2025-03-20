// D:\AndroidStudioProjects\vnvar_flutter\lib\services\scoreboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScoreboardService {
  Future<Map<String, int>?> fetchScore(String ip, String table) async {
    final url = Uri.parse('http://$ip/home/getscore?tb=$table');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scoreA = data['score_a'];
        final scoreB = data['score_b'];

        // Kiểm tra dữ liệu hợp lệ
        if (scoreA is int && scoreB is int) {
          return {'score_a': scoreA, 'score_b': scoreB};
        } else {
          print('Dữ liệu từ API không hợp lệ: $data');
          return null; // Trả về null nếu dữ liệu không phải số nguyên
        }
      } else {
        print('API trả về lỗi: ${response.statusCode}');
        return null; // Trả về null nếu API lỗi
      }
    } catch (error) {
      print('Lỗi khi gọi API: $error');
      return null; // Trả về null nếu có lỗi mạng hoặc timeout
    }
  }
}