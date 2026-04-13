import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your machine's local IP for Android device testing
  // e.g., 'http://192.168.1.100:8000'
  static const String baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> predict(String text,
      {int topK = 3}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'top_k': topK}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Prediction failed: ${res.statusCode}');
  }

  static Future<String> generateFir({
    required String complainantName,
    required String description,
    required List<String> sections,
    String dateOfOccurrence = 'Not specified',
    String timeOfOccurrence = 'Not specified',
    String placeOfOccurrence = 'Not specified',
    String policeStation = 'Not specified',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/generate_fir'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'complainant_name': complainantName,
        'description': description,
        'sections': sections,
        'date_of_occurrence': dateOfOccurrence,
        'time_of_occurrence': timeOfOccurrence,
        'place_of_occurrence': placeOfOccurrence,
        'police_station': policeStation,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['draft'];
    throw Exception('FIR generation failed: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> sectionInfo(String section) async {
    final res = await http.get(Uri.parse('$baseUrl/section_info/$section'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Section info failed: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> ocrExtract(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/ocr'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('OCR failed: ${res.statusCode}');
  }

  /// Translate text to target language (default: English)
  static Future<Map<String, dynamic>> translateText(String text,
      {String targetLang = 'en'}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'target_lang': targetLang}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Translation failed: ${res.statusCode}');
  }

  static Future<bool> healthCheck() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
