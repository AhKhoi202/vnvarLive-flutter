import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart'; // Thư viện đăng nhập Google
import 'package:http/http.dart' as http; // Thư viện HTTP cho API calls
import '../constants/api_constants.dart'; // Hằng số API

class YoutubeService {
  // Khởi tạo Google Sign-In với các scope cần thiết
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/youtube.force-ssl', // Quyền truy cập YouTube
      'https://www.googleapis.com/auth/userinfo.profile', // Quyền lấy thông tin người dùng
    ],
  );

  // Các biến private lưu trữ dữ liệu
  GoogleSignInAccount? _currentUser; // Người dùng hiện tại
  String? _accessToken; // Access token từ Google
  String? _broadcastId; // ID của broadcast
  String? _streamId; // ID của stream
  String? _streamKey; // Key để gửi luồng RTMP
  String? _liveUrl; // URL phát trực tiếp

  // Getter để truy cập từ ngoài
  GoogleSignInAccount? get currentUser => _currentUser;
  set currentUser(GoogleSignInAccount? value) => _currentUser = value; // Setter cho currentUser
  String? get accessToken => _accessToken;
  String? get streamKey => _streamKey;
  String? get liveUrl => _liveUrl;
  Stream<GoogleSignInAccount?> get onCurrentUserChanged => _googleSignIn.onCurrentUserChanged;

  Future<void> signIn() async => await _googleSignIn.signIn(); // Đăng nhập thủ công
  Future<void> signInSilently() async => await _googleSignIn.signInSilently(); // Đăng nhập ngầm
  Future<void> signOut() async => await _googleSignIn.disconnect(); // Đăng xuất

  Future<void> getToken() async {
    final auth = await _currentUser!.authentication; // Lấy thông tin xác thực
    _accessToken = auth.accessToken; // Lưu access token
  }

  Future<String?> getUserName() async {
    final response = await http.get(
      Uri.parse(ApiConstants.userInfoUrl), // Gửi GET request tới API Google
      headers: {'Authorization': 'Bearer $_accessToken'}, // Đính kèm token
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); // Parse JSON
      return data['name']; // Trả về tên người dùng
    }
    return null; // Trả về null nếu thất bại
  }

  Future<void> createLiveBroadcastAndStream() async {
    // Tạo broadcast
    final broadcastResponse = await http.post(
      // Uri.parse(ApiConstants.liveBroadcastUrl),
      Uri.parse('${ApiConstants.liveBroadcastUrl}?part=snippet,contentDetails,status'),

      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'snippet': {
          'title': 'Live Stream ${DateTime.now().millisecondsSinceEpoch}', // Tiêu đề động
          'scheduledStartTime': DateTime.now().add(const Duration(minutes: 1)).toIso8601String(),
          'description': 'Test broadcast từ ứng dụng Flutter',
        },
        'contentDetails': {'enableAutoStart': false, 'enableAutoStop': true},
        'status': {'privacyStatus': 'unlisted', 'selfDeclaredMadeForKids': false},
      }),
    );

    if (broadcastResponse.statusCode != 200) {
      throw Exception('Không thể tạo broadcast: ${broadcastResponse.body}');
    }

    final broadcastData = jsonDecode(broadcastResponse.body);
    _broadcastId = broadcastData['id'];
    _liveUrl = 'https://www.youtube.com/watch?v=$_broadcastId';

    // Tạo stream
    final streamResponse = await http.post(
      Uri.parse('${ApiConstants.liveStreamUrl}?part=snippet,cdn'),
      // Uri.parse(ApiConstants.liveStreamUrl),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'snippet': {'title': 'Live Stream ${DateTime.now().millisecondsSinceEpoch}'},
        'cdn': {'ingestionType': 'rtmp', 'resolution': '720p', 'frameRate': '30fps'},
      }),
    );

    if (streamResponse.statusCode != 200) {
      throw Exception('Không thể tạo stream: ${streamResponse.body}');
    }

    final streamData = jsonDecode(streamResponse.body);
    _streamId = streamData['id'];
    _streamKey = streamData['cdn']['ingestionInfo']['streamName'];

    // Liên kết broadcast với stream
    final bindResponse = await http.post(
      Uri.parse('${ApiConstants.liveBroadcastBindUrl}?id=$_broadcastId&streamId=$_streamId&part=id'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (bindResponse.statusCode != 200) {
      throw Exception('Không thể liên kết stream: ${bindResponse.body}');
    }
  }

  Future<bool> isStreamActive() async {
    print("_streamId: $_streamId _accessToken $_accessToken");
    if (_streamId == null || _accessToken == null) return false;
    final response = await http.get(
      Uri.parse('${ApiConstants.liveStreamUrl}?part=status&id=$_streamId'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    print('${ApiConstants.liveStreamUrl}?part=status&id=$_streamId');
    print('response: $response');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final status = data['items'][0]['status']['streamStatus'];
      return status == 'active'; // Trả về true nếu luồng active
    }
    return false;
  }

  // Thêm hàm kiểm tra trạng thái broadcast
  Future<String> getBroadcastStatus() async {
    print('_broadcastId $_broadcastId _accessToken $_accessToken');
    if (_broadcastId == null || _accessToken == null) return 'unknown';
    final response = await http.get(
      Uri.parse('${ApiConstants.liveBroadcastUrl}?part=status&id=$_broadcastId'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    print('${ApiConstants.liveBroadcastUrl}?part=status&id=$_broadcastId');
    print('response ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'][0]['status']['lifeCycleStatus'];
    }
    return 'unknown';
  }

  // Chuyển broadcast sang trạng thái testing trước nếu cần
  Future<void> transitionToTesting() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.liveBroadcastTransitionUrl}?broadcastStatus=testing&id=$_broadcastId&part=status'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode != 200) {
      print('Không thể chuyển sang trạng thái testing: ${response.body}');
      throw Exception('Không thể chuyển sang trạng thái testing: ${response.body}');
    }
  }

  Future<void> waitForTestingStatus() async {
    print('Đang chờ trạng thái testing...');
    for (int i = 0; i < 10; i++) { // Chờ tối đa 20 giây (10 lần x 2 giây)
      final status = await getBroadcastStatus();
      print('Kiểm tra trạng thái lần $i: $status');
      if (status == 'testing') {
        print('Đã đạt trạng thái testing');
        return;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    throw Exception('Không thể đạt trạng thái testing sau 20 giây');
  }

  Future<void> startLiveStream() async {
    // Kiểm tra trạng thái hiện tại của broadcast
    final currentStatus = await getBroadcastStatus();
    print('Current broadcast status: $currentStatus');
    if (currentStatus == 'live') {
      print('Broadcast đã ở trạng thái live');
      return;
    }
// Nếu chưa ở trạng thái testing, chuyển sang testing và chờ
    if (currentStatus != 'testing') {
      print('Chưa ở trạng thái testing, thử chuyển sang testing trước');
      try {
        await transitionToTesting();
        await waitForTestingStatus(); // Chờ cho đến khi trạng thái là testing
      } catch (e) {
        if (e.toString().contains('redundantTransition')) {
          print('Broadcast đã ở trạng thái testing, tiếp tục sang live');
          await waitForTestingStatus(); // Vẫn chờ để đảm bảo
        } else {
          rethrow;
        }
      }
    }

    // Kiểm tra lại trạng thái sau khi chuyển sang testing
    final statusAfterTesting = await getBroadcastStatus();
    print('Trạng thái trước khi chuyển sang live: $statusAfterTesting');

    final response = await http.post(
      Uri.parse('${ApiConstants.liveBroadcastTransitionUrl}?broadcastStatus=live&id=$_broadcastId&part=status'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    print('${ApiConstants.liveBroadcastTransitionUrl}?broadcastStatus=live&id=$_broadcastId&part=status');
    print('response startLiveStream: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('Không thể chuyển sang trạng thái live: ${response.body}');
    }
  }

  Future<void> stopLiveStream() async {
    if (_broadcastId != null && _accessToken != null) {
      await http.post(
        Uri.parse('${ApiConstants.liveBroadcastTransitionUrl}?broadcastStatus=complete&id=$_broadcastId&part=status'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
    }
  }
}