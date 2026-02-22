import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Service to communicate with the Node.js backend API.
/// Firebase Auth tokens are sent with every request for verification.
class ApiService {
  // Production backend on Render
  static const String _baseUrl = 'https://agroconnect-api-g92l.onrender.com/api';
  static const String _serverUrl = 'https://agroconnect-api-g92l.onrender.com';

  /// Public accessor for base URL (used by ProduceService for multipart uploads)
  static String get baseUrl => _baseUrl;

  /// Parse JSON response body
  static Map<String, dynamic> parseJson(String body) => jsonDecode(body);

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's Firebase ID token
  static Future<String?> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Build authorization headers
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── USER ENDPOINTS ───────────────────────────────────

  /// Get current user's profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/profile'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  /// Update current user's profile
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  /// Get a user's public profile
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // ─── PRODUCE ENDPOINTS ────────────────────────────────

  /// Get all produce with optional filters
  static Future<Map<String, dynamic>> getAllProduce({
    String? status,
    String? category,
    String? search,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'status': ?status,
      'category': ?category,
      'search': ?search,
    };

    final uri = Uri.parse('$_baseUrl/produce').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// Get a single produce item
  static Future<Map<String, dynamic>> getProduceById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/produce/$id'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  /// Get current farmer's produce
  static Future<Map<String, dynamic>> getMyProduce() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/produce/mine'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  /// Create new produce
  static Future<Map<String, dynamic>> createProduce(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/produce'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  /// Update produce
  static Future<Map<String, dynamic>> updateProduce(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/produce/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  /// Delete produce
  static Future<Map<String, dynamic>> deleteProduce(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/produce/$id'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  /// Upload produce image
  static Future<Map<String, dynamic>> uploadProduceImage(
      String produceId, File imageFile) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/produce/$produceId/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // ─── CHAT ENDPOINTS ──────────────────────────────────

  /// Get or create a chat room
  static Future<Map<String, dynamic>> getOrCreateChatRoom({
    required String otherUserId,
    String? produceId,
    String? produceName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/room'),
      headers: await _headers(),
      body: jsonEncode({
        'otherUserId': otherUserId,
        'produceId': ?produceId,
        'produceName': ?produceName,
      }),
    );
    return _handleResponse(response);
  }

  /// Get user's chat rooms
  static Future<Map<String, dynamic>> getMyChatRooms() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/rooms'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  /// Send a chat message
  static Future<Map<String, dynamic>> sendMessage({
    required String chatRoomId,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/message'),
      headers: await _headers(),
      body: jsonEncode({
        'chatRoomId': chatRoomId,
        'text': text,
      }),
    );
    return _handleResponse(response);
  }

  /// Get messages for a chat room
  static Future<Map<String, dynamic>> getMessages(
    String chatRoomId, {
    int limit = 50,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/$chatRoomId/messages')
        .replace(queryParameters: {'limit': limit.toString()});
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// Mark messages as read
  static Future<Map<String, dynamic>> markChatAsRead(
      String chatRoomId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/chat/$chatRoomId/read'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // ─── NOTIFICATION ENDPOINTS ───────────────────────────

  /// Get user's notifications
  static Future<Map<String, dynamic>> getNotifications({
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (unreadOnly) 'unreadOnly': 'true',
    };

    final uri =
        Uri.parse('$_baseUrl/notifications').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: await _headers(),
    );
    final data = _handleResponse(response);
    return data['unreadCount'] ?? 0;
  }

  /// Mark a notification as read
  static Future<void> markNotificationAsRead(String id) async {
    await http.put(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: await _headers(),
    );
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    await http.put(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: await _headers(),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────

  /// Convert a relative image path (e.g. /api/images/abc123)
  /// to a full URL that can be used with Image.network()
  static String getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    return '$_serverUrl$imageUrl';
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: body['error'] ?? 'Unknown error',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
