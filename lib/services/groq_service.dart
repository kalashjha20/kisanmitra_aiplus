import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _url =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<Map<String, dynamic>> getDiseaseInfo(
      String diseaseName) async {
    try {
      debugPrint("🌐 Getting info for: $diseaseName");

      // ✅ Check if API key exists
      if (_apiKey.isEmpty) {
        return {
          'success': false,
          'error': 'API key missing. Check .env file'
        };
      }

      final cleanName = diseaseName
          .replaceAll(' - ', ' ')
          .replaceAll('_', ' ')
          .trim();

      final prompt = '''
You are a plant disease expert. Provide detailed information about "$cleanName".

If this is a healthy plant (contains word "healthy"), describe how to maintain plant health.

Respond ONLY in this exact JSON format with no extra text outside JSON:
{
  "description": "2-3 sentence description of this disease or condition",
  "symptoms": ["symptom 1", "symptom 2", "symptom 3"],
  "causes": ["cause 1", "cause 2"],
  "treatment": ["step 1", "step 2", "step 3", "step 4"],
  "prevention": ["tip 1", "tip 2", "tip 3"]
}
''';

      final body = jsonEncode({
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "messages": [
          {
            "role": "user",
            "content": prompt
          }
        ],
        "temperature": 0.2,
        "max_tokens": 800,
      });

      debugPrint("🔗 Calling Groq API...");

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      debugPrint("📡 Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];

        debugPrint("📝 Groq response: $text");

        final cleanJson = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        return {
          'success': true,
          'data': jsonDecode(cleanJson)
        };

      } else {
        debugPrint("❌ Groq Error: ${response.statusCode}");
        debugPrint("❌ Body: ${response.body}");
        return {
          'success': false,
          'error': 'API error ${response.statusCode}'
        };
      }

    } on TimeoutException {
      debugPrint("❌ Groq timeout");
      return {'success': false, 'error': 'Request timed out'};

    } on SocketException catch (e) {
      debugPrint("❌ No internet: $e");
      return {'success': false, 'error': 'No internet'};

    } catch (e, stackTrace) {
      debugPrint("❌ Groq Exception: $e");
      debugPrint("❌ Stack: $stackTrace");
      return {'success': false, 'error': e.toString()};
    }
  }
}