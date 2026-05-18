import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/models/destination.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';

class DestinationRepository {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService();

  // --- Fetches the initial list from YOUR backend ---
  Future<List<Destination>> getDestinationIdeas({String? query}) async {
    final token = await _storageService.readToken();
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.destinationsUrl}',
        queryParameters: {'search': query},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        List<dynamic> destinationData = response.data['data']['destinations'];
        return destinationData
            .map((json) => Destination.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load destination ideas');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message;
      throw Exception('Network Error: $errorMsg');
    }
  }

  // --- UPDATED: Fetches rich details from the Gemini API with a better prompt ---
  Future<String> getDestinationDetails(
      String destinationName, String country) async {
    const apiKey =
        "AIzaSyAFdkNdDcQcS0CotfQ2J525059HmvX4hcQ"; // Handled automatically
    const url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey';

    // --- THIS IS THE FIX ---
    final prompt = """
          Generate a highly detailed and comprehensive travel guide for a tourist visiting '$destinationName, $country'. 
          The tone should be engaging, informative, and practical. 
          Do not use markdown, asterisks, or special symbols like #. 
          Use plain text only. 
          Make all main section titles and important keywords in bold using Unicode bold letters. 
          Use '-' for bullet points.

          Follow this structure exactly:

          𝗜𝗡𝗧𝗥𝗢𝗗𝗨𝗖𝗧𝗜𝗢𝗡:
          Write a short paragraph describing where '𝗗𝗘𝗦𝗧𝗜𝗡𝗔𝗧𝗜𝗢𝗡 𝗡𝗔𝗠𝗘, 𝗖𝗢𝗨𝗡𝗧𝗥𝗬' is located and what it is famous for.

          𝗠𝗨𝗦𝗧-𝗩𝗜𝗦𝗜𝗧 𝗣𝗟𝗔𝗖𝗘𝗦:
          - 𝗣𝗹𝗮𝗰𝗲 1: Brief, exciting description.
          - 𝗣𝗹𝗮𝗰𝗲 2: Brief, exciting description.
          - 𝗣𝗹𝗮𝗰𝗲 3: Brief, exciting description.
          - 𝗣𝗹𝗮𝗰𝗲 4: Brief, exciting description.
          - 𝗣𝗹𝗮𝗰𝗲 5: Brief, exciting description.

          𝗙𝗔𝗠𝗢𝗨𝗦 𝗦𝗛𝗢𝗣𝗦 𝗔𝗡𝗗 𝗠𝗔𝗥𝗞𝗘𝗧𝗦:
          - 𝗦𝗵𝗼𝗽 1: Brief description of what makes it special.
          - 𝗦𝗵𝗼𝗽 2: Brief description of what makes it unique.
          

          𝗕𝗘𝗦𝗧 𝗛𝗢𝗧𝗘𝗟𝗦 𝗔𝗡𝗗 𝗥𝗘𝗦𝗢𝗥𝗧𝗦:
          - 𝗟𝘂𝘅𝘂𝗿𝘆: Hotel Name - Reason.
          - 𝗠𝗶𝗱-𝗥𝗮𝗻𝗴𝗲: Hotel Name - Reason.
          - 𝗕𝘂𝗱𝗴𝗲𝘁: Hotel Name - Reason.

          𝗟𝗢𝗖𝗔𝗟 𝗖𝗨𝗜𝗦𝗜𝗡𝗘 𝗧𝗢 𝗧𝗥𝗬:
          - 𝗗𝗶𝘀𝗵 1: Brief, delicious description.
          - 𝗗𝗶𝘀𝗵 2: Brief, delicious description.
          - 𝗗𝗶𝘀𝗵 3: Brief, delicious description.

          𝗘𝗦𝗦𝗘𝗡𝗧𝗜𝗔𝗟 𝗧𝗥𝗔𝗩𝗘𝗟 𝗧𝗜𝗣𝗦:
          - 𝗧𝗶𝗽 1.
          - 𝗧𝗶𝗽 2.
          - 𝗧𝗶𝗽 3.
    """;

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
        return response.data['candidates'][0]['content']['parts'][0]['text']
            .trim();
      } else {
        throw Exception('Failed to get a valid response from the AI.');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('AI generation failed: $errorMsg');
    }
  }
}
