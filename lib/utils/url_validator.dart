bool isValidRtspUrl(String url) {
  return url.isNotEmpty && url.startsWith('rtsp://');
}