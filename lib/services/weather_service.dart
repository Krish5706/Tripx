import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WeatherService {
  /// 🌡 Get current weather at destination
  static Future<Map<String, dynamic>?> getCurrentWeather(
      double lat, double lng) async {
    final url =
        '${APIConfig.visualCrossingBaseUrl}/$lat,$lng?unitGroup=metric&key=${APIConfig.visualCrossingApiKey}&include=current';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "temperature": data['currentConditions']?['temp'],
          "condition": data['currentConditions']?['conditions'],
          "icon": data['currentConditions']?['icon'],
          "humidity": data['currentConditions']?['humidity'],
          "wind": data['currentConditions']?['windspeed'],
        };
      }
    } catch (e) {
      developer.log("Error fetching current weather: $e", name: 'WeatherService');
    }
    return null;
  }

  /// 📆 Get 7-day weather forecast
  static Future<List<Map<String, dynamic>>> getForecast(
      double lat, double lng) async {
    final url =
        '${APIConfig.visualCrossingBaseUrl}/$lat,$lng?unitGroup=metric&key=${APIConfig.visualCrossingApiKey}&include=days&elements=datetime,tempmax,tempmin,conditions,icon';

    List<Map<String, dynamic>> forecast = [];

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['days'] != null) {
          for (var day in data['days']) {
            forecast.add({
              "date": day['datetime'],
              "tempMax": day['tempmax'],
              "tempMin": day['tempmin'],
              "condition": day['conditions'],
              "icon": day['icon'],
            });
          }
        }
      }
    } catch (e) {
      developer.log("Error fetching forecast: $e", name: 'WeatherService');
    }
    return forecast;
  }

  /// 📊 Climate trend by month (static / Visual Crossing seasonal averages)
  static Future<List<Map<String, dynamic>>> getClimateTrends(
      double lat, double lng) async {
    final url =
        '${APIConfig.visualCrossingBaseUrl}/$lat,$lng?unitGroup=metric&key=${APIConfig.visualCrossingApiKey}&include=stats';

    List<Map<String, dynamic>> trends = [];

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['months'] != null) {
          for (var month in data['months']) {
            trends.add({
              "month": month['month'],
              "avgTemp": month['temp'],
              "avgRain": month['precip'],
            });
          }
        }
      }
    } catch (e) {
      developer.log("Error fetching climate trends: $e", name: 'WeatherService');
    }
    return trends;
  }
}
