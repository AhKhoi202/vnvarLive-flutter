// import 'package:hive_flutter/hive_flutter.dart';
//
// class HiveService {
//   static const String _boxName = 'rtspBox';
//   static const String _rtspUrlKey = 'rtsp_url';
//
//   // Lưu URL RTSP
//   static Future<void> saveRtspUrl(String url) async {
//     final box = await Hive.openBox(_boxName);
//     await box.put(_rtspUrlKey, url);
//   }
//
//   // Đọc URL RTSP
//   static Future<String?> getRtspUrl() async {
//     final box = await Hive.openBox(_boxName);
//     return box.get(_rtspUrlKey);
//   }
// }