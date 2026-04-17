import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static String get apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  static Future<Map<String, dynamic>> fetchWeather(
      double lat, double lon) async {

    if (apiKey.isEmpty) {
      throw Exception("API key missing. Check .env file");
    }

    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load weather (${response.statusCode})");
    }
  }
}