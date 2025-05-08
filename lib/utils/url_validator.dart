// D:\AndroidStudioProjects\vnvar_flutter\lib\utils\url_validator.dart
bool isValidRtspUrl(String url) {
  // Trim whitespace từ đầu và cuối URL
  url = url.trim();
  // Kiểm tra URL rỗng
  if (url.isEmpty) return false;
  // Nếu không bắt đầu bằng rtsp://, thử thêm vào
  if (!url.startsWith('rtsp://')) {
    url = 'rtsp://$url';
  }
  // Regex để kiểm tra định dạng URL RTSP
  final rtspRegex = RegExp(r'^rtsp://(\w+:?\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?$');
  return rtspRegex.hasMatch(url);
}