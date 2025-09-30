import 'dart:convert';
import 'package:dio/dio.dart';

class TranslatorRepository {
  final Dio _dio = Dio();

  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // In this environment, the API key is handled automatically.
    // We leave this empty.
    const String apiKey = "AIzaSyCmBHhKnrgjZtdXeXv6qW7hT1XYcrAvldo"; 

    const url ='https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=$apiKey';

    // --- REFINED PROMPT ---
    // This prompt is very specific to ensure the AI only returns the translation.
    final prompt =
        "Translate the following text from $sourceLanguage to $targetLanguage. Provide only the translated text, with no additional commentary, explanations, or phonetic transcription: '$text'";

    final payload = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    try {
      final response = await _dio.post(
        url,
        data: jsonEncode(payload),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Extract the translated text from the Gemini API response
        final translatedText =
            response.data['candidates'][0]['content']['parts'][0]['text'];
        return translatedText.trim();
      } else {
        throw Exception('Failed to get a valid translation response.');
      }
    } on DioException catch (e) {
      // Provide a more detailed error message
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Translation failed: $errorMsg');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}

