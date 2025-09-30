import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIConfig {
  // 🌦 Weather API (Visual Crossing)
  static String get visualCrossingApiKey =>
      dotenv.env['VISUAL_CROSSING_API_KEY'] ?? 'WGFBZHMGBKRDAPZ843Z9M44PP';

  static String get visualCrossingBaseUrl =>
      'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline';

  // 🌍 RoadGoat API
  static String get roadGoatApiKey => dotenv.env['ROADGOAT_API_KEY'] ?? '';
  static String get roadGoatApiSecret => dotenv.env['ROADGOAT_API_SECRET'] ?? '';
  static String get roadGoatBaseUrl => 'https://api.roadgoat.com/api/v2/destinations';

  // 📖 Wikivoyage / Wikipedia (static or scraped)
  static String get wikivoyageBaseUrl => 'https://en.wikivoyage.org/wiki/';

  // 📸 SerpApi (for images & trending)
  static String get serpApiKey => dotenv.env['SERP_API_KEY'] ?? '2e5d1989d72622af5e3eed6b1ab4ba2db7142a1b6a09d3bef63c02d496eb686d';
  static String get serpApiBaseUrl => 'https://serpapi.com/search';

  // 🏨 Tripadvisor API (optional)
  static String get tripAdvisorApiKey =>
      dotenv.env['TRIPADVISOR_API_KEY'] ?? '';
  static String get tripAdvisorBaseUrl => 'https://api.tripadvisor.com/api';

  // 📸 Unsplash API (for images)
  static String get unsplashApiKey => dotenv.env['UNSPLASH_API_KEY'] ?? 'f5WUTJCbPcTRXkpShq21BE0W7VLtUXQWAKy9AwF9KIo';

  // 🛰 Teleport API (for geolocation)
  static String get teleportApiKey => dotenv.env['TELEPORT_API_KEY'] ?? '';

  // 🤖 PromptJoy API
  static String get promptJoyApiKey => dotenv.env['PROMPTJOY_API_KEY'] ?? '';
  static String get promptJoyBaseUrl => 'https://api.promptjoy.com/v1/recommend';

  // Common headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };
}
