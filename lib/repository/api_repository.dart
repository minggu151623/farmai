import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiRepository {
  static final ApiRepository _instance = ApiRepository._internal();
  factory ApiRepository() => _instance;
  ApiRepository._internal();

  String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000';

  /// GET /test — test server connectivity
  Future<ApiResponse> testConnection() async {
    return _get('/test');
  }

  /// POST /chat — send a chat message with history
  Future<ApiResponse> sendChat({
    required String question,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    return post('/chat', body: {
      'question': question,
      'chat_history': chatHistory,
    });
  }

  /// Generic GET request
  Future<ApiResponse> _get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body,
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        body: 'Lỗi kết nối: $e',
        isSuccess: false,
      );
    }
  }

  /// Generic POST request
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 15),
      );
      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body,
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        body: 'Lỗi kết nối: $e',
        isSuccess: false,
      );
    }
  }
}

class ApiResponse {
  final int statusCode;
  final String body;
  final bool isSuccess;

  const ApiResponse({
    required this.statusCode,
    required this.body,
    required this.isSuccess,
  });

  Map<String, dynamic>? get json {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'ApiResponse(status: $statusCode, body: $body)';
}
