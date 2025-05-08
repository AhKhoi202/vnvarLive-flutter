import 'dart:convert';
import 'package:http/http.dart' as http;

class ScoreboardService {
  Future<Map<String, dynamic>?> fetchScore(String ip, String table) async {
    final url = Uri.parse('http://$ip/home/getscore?tb=$table');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Kiểm tra dữ liệu có phải là Map hợp lệ
        if (data is Map<String, dynamic>) {
          return data; // Trả về toàn bộ dữ liệu JSON
        } else {
          print('Dữ liệu từ API không hợp lệ: $data');
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
}