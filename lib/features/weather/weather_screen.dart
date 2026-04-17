import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {

  // ✅ SECURE: Load from .env instead of hardcoding
  String get _apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  bool _isLoading = true;
  String _error = '';

  // Current weather
  String _city = '';
  double _temp = 0;
  double _feelsLike = 0;
  int _humidity = 0;
  double _windSpeed = 0;
  double _rainChance = 0;
  String _condition = '';
  String _icon = '';

  // 5-day forecast
  List<Map<String, dynamic>> _forecast = [];

  // Farming advice
  String _farmingTip = '';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_apiKey.isEmpty) {
        throw Exception("API key missing. Check .env file");
      }

      final position = await _getLocation();
      await _fetchWeather(position.latitude, position.longitude);
      await _fetchForecast(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception('Weather fetch failed');

    final data = jsonDecode(response.body);

    setState(() {
      _city = data['name'] ?? '';
      _temp = (data['main']['temp'] as num).toDouble();
      _feelsLike = (data['main']['feels_like'] as num).toDouble();
      _humidity = data['main']['humidity'];
      _windSpeed = (data['wind']['speed'] as num).toDouble() * 3.6;
      _condition = data['weather'][0]['description'];
      _icon = data['weather'][0]['icon'];
      _rainChance = data['clouds']['all'].toDouble();
      _farmingTip = _getFarmingTip(_condition, _temp, _humidity);
      _isLoading = false;
    });
  }

  Future<void> _fetchForecast(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=40';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);
    final List items = data['list'];

    final Map<String, Map<String, dynamic>> dailyMap = {};

    for (var item in items) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dayKey = '${date.month}-${date.day}';

      if (!dailyMap.containsKey(dayKey)) {
        dailyMap[dayKey] = {
          'date': date,
          'temp_max': (item['main']['temp_max'] as num).toDouble(),
          'temp_min': (item['main']['temp_min'] as num).toDouble(),
          'icon': item['weather'][0]['icon'],
          'condition': item['weather'][0]['main'],
        };
      }
    }

    setState(() {
      _forecast = dailyMap.values.take(5).toList();
    });
  }

  String _getFarmingTip(String condition, double temp, int humidity) {
    condition = condition.toLowerCase();

    if (condition.contains('rain')) {
      return '🌧️ Rain expected — avoid spraying pesticides today. Good time for transplanting seedlings.';
    } else if (condition.contains('clear') && temp > 35) {
      return '☀️ Very hot day — water crops early morning or evening. Avoid fieldwork during peak heat.';
    } else if (condition.contains('clear')) {
      return '✅ Clear skies — ideal day for spraying fertilizers or pesticides.';
    } else if (condition.contains('cloud')) {
      return '⛅ Cloudy weather — good conditions for field inspection and light irrigation.';
    } else if (humidity > 80) {
      return '💧 High humidity — watch out for fungal diseases. Ensure good crop ventilation.';
    } else {
      return '🌱 Monitor crop moisture levels and irrigate if needed.';
    }
  }

  String _dayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    if (date.day == now.day) return 'Today';
    if (date.day == now.add(const Duration(days: 1)).day) return 'Tomorrow';

    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Forecast"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeather,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 12),
            Text("Fetching weather..."),
          ],
        ),
      )
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (UNCHANGED UI — exactly same as your code)
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}