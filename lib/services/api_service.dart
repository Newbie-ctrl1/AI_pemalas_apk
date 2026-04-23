import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/chat_thread.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  Uri _uri(String path) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$suffix');
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(data['message']?.toString() ?? 'Register gagal (${response.statusCode})');
  }

  Future<String> login({required String email, required String password}) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data['access_token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan di response login');
      }
      return token;
    }

    throw Exception(data['message']?.toString() ?? 'Login gagal (${response.statusCode})');
  }

  Future<String> sendChat({required String prompt, required String token}) async {
    return sendChatToThread(prompt: prompt, token: token);
  }

  Future<String> sendChatToThread({
    required String prompt,
    required String token,
    int? threadId,
  }) async {
    final response = await http.post(
      _uri('/api/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'prompt': prompt,
        if (threadId != null) 'thread_id': threadId,
      }),
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final chat = data['chat'];
      if (chat is Map && chat['response'] != null) {
        return chat['response'].toString();
      }
      throw Exception('Response chat tidak valid');
    }

    throw Exception(data['message']?.toString() ?? 'Chat gagal (${response.statusCode})');
  }

  Future<List<ChatThread>> getThreads({
    required String token,
    String? query,
  }) async {
    final uri = _uri('/api/chat/threads').replace(
      queryParameters: query != null && query.trim().isNotEmpty
          ? {'query': query.trim()}
          : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final rows = data['threads'];
      if (rows is List) {
        return rows
            .whereType<Map>()
            .map((row) => ChatThread.fromJson(Map<String, dynamic>.from(row)))
            .where((thread) => thread.id > 0)
            .toList();
      }
      return <ChatThread>[];
    }

    throw Exception(data['message']?.toString() ?? 'Gagal ambil thread (${response.statusCode})');
  }

  Future<ChatThread> createThread({
    required String token,
    String? title,
  }) async {
    final response = await http.post(
      _uri('/api/chat/threads'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({if (title != null && title.trim().isNotEmpty) 'title': title.trim()}),
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final thread = data['thread'];
      if (thread is Map) {
        return ChatThread.fromJson(Map<String, dynamic>.from(thread));
      }
      throw Exception('Response thread tidak valid');
    }

    throw Exception(data['message']?.toString() ?? 'Gagal buat thread (${response.statusCode})');
  }

  Future<void> deleteThread({
    required String token,
    required int threadId,
  }) async {
    final response = await http.delete(
      _uri('/api/chat/threads/$threadId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(data['message']?.toString() ?? 'Gagal hapus thread (${response.statusCode})');
  }

  Future<List<Map<String, dynamic>>> getThreadMessages({
    required String token,
    required int threadId,
  }) async {
    final response = await http.get(
      _uri('/api/chat/threads/$threadId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final rows = data['messages'];
      if (rows is List) {
        return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
      }
      return <Map<String, dynamic>>[];
    }

    throw Exception(data['message']?.toString() ?? 'Gagal ambil pesan thread (${response.statusCode})');
  }

  Future<List<Map<String, dynamic>>> getChatHistory({
    required String token,
    String? query,
  }) async {
    final uri = _uri('/api/chat/history').replace(
      queryParameters: query != null && query.trim().isNotEmpty
          ? {'query': query.trim()}
          : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final history = data['history'];
      if (history is List) {
        return history.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return <Map<String, dynamic>>[];
    }

    throw Exception(data['message']?.toString() ?? 'Gagal ambil history (${response.statusCode})');
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final parsed = jsonDecode(body);
    if (parsed is Map<String, dynamic>) return parsed;
    return <String, dynamic>{};
  }
}
