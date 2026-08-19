import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  static Future<AnalysisResult> analyzeText({
    required String baseUrl,
    required String path,
    required String content,
    required String requestId,
  }) {
    final body = <String, dynamic>{
      'input_type': 'text',
      'content': content,
      'request_id': requestId,
      'language': 'th',
      'metadata': {'source': 'flutter-demo'},
    };
    return _post(baseUrl, path, body);
  }

  static Future<AnalysisResult> analyzeMedia({
    required String baseUrl,
    required String path,
    required String inputType, // "image" | "audio"
    required String mimeType,
    required String base64Data,
    required String requestId,
  }) {
    final body = <String, dynamic>{
      'input_type': inputType,
      'content': {
        'mime_type': mimeType,
        'data': base64Data,
      },
      'request_id': requestId,
      'language': 'th',
      'metadata': {'source': 'flutter-demo'},
    };
    return _post(baseUrl, path, body);
  }

  static Future<AnalysisResult> _post(
    String baseUrl,
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(_joinUrl(baseUrl, path));

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw ApiException(
        httpStatus: 0,
        code: 'NETWORK_ERROR',
        message: 'ไม่สามารถเชื่อมต่อ API ได้ กรุณาตรวจสอบ API Base URL และเครือข่าย',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        httpStatus: response.statusCode,
        code: null,
        message: 'การตอบกลับจาก API ไม่ถูกต้อง',
      );
    }

    if (response.statusCode != 200) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw ApiException(
        httpStatus: response.statusCode,
        code: error?['code'] as String?,
        message: (error?['message'] as String?) ?? 'กรุณาลองใหม่ภายหลัง',
      );
    }

    return AnalysisResult.fromJson(decoded);
  }

  static String _joinUrl(String baseUrl, String path) {
    final b = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }
}
