// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
//
// class WeatherScreen extends StatefulWidget {
//   const WeatherScreen({super.key});
//
//   @override
//   State<WeatherScreen> createState() => _WeatherScreenState();
// }
//
// class _WeatherScreenState extends State<WeatherScreen> {
//   // ✅ SECURE: Load from .env instead of hardcoding
//   String get _apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
//
//   bool _isLoading = true;
//   String _error = '';
//
//   // Current weather
//   String _city = '';
//   double _temp = 0;
//   double _feelsLike = 0;
//   int _humidity = 0;
//   double _windSpeed = 0;
//   double _rainChance = 0;
//   String _condition = '';
//   String _icon = '';
//
//   // 5-day forecast
//   List<Map<String, dynamic>> _forecast = [];
//
//   // Farming advice
//   String _farmingTip = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadWeather();
//   }
//
//   Future<void> _loadWeather() async {
//     setState(() {
//       _isLoading = true;
//       _error = '';
//     });
//
//     try {
//       if (_apiKey.isEmpty) {
//         throw Exception("API key missing. Check .env file");
//       }
//
//       final position = await _getLocation();
//       await _fetchWeather(position.latitude, position.longitude);
//       await _fetchForecast(position.latitude, position.longitude);
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<Position> _getLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) throw Exception('Location services disabled');
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         throw Exception('Location permission denied');
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       throw Exception(
//           'Location permissions permanently denied. Please enable in settings.');
//     }
//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.medium,
//     );
//   }
//
//   Future<void> _fetchWeather(double lat, double lon) async {
//     final url =
//         'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
//
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode != 200) {
//       throw Exception('Weather fetch failed (${response.statusCode})');
//     }
//
//     final data = jsonDecode(response.body);
//
//     setState(() {
//       _city = data['name'] ?? 'Unknown Location';
//       _temp = (data['main']['temp'] as num).toDouble();
//       _feelsLike = (data['main']['feels_like'] as num).toDouble();
//       _humidity = data['main']['humidity'];
//       _windSpeed = (data['wind']['speed'] as num).toDouble() * 3.6;
//       _condition = data['weather'][0]['description'];
//       _icon = data['weather'][0]['icon'];
//       _rainChance = (data['clouds']['all'] as num).toDouble();
//       _farmingTip = _getFarmingTip(_condition, _temp, _humidity);
//       _isLoading = false;
//     });
//   }
//
//   Future<void> _fetchForecast(double lat, double lon) async {
//     final url =
//         'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=40';
//
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode != 200) return;
//
//     final data = jsonDecode(response.body);
//     final List items = data['list'];
//
//     final Map<String, Map<String, dynamic>> dailyMap = {};
//
//     for (var item in items) {
//       final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
//       final dayKey = '${date.month}-${date.day}';
//
//       if (!dailyMap.containsKey(dayKey)) {
//         dailyMap[dayKey] = {
//           'date': date,
//           'temp_max': (item['main']['temp_max'] as num).toDouble(),
//           'temp_min': (item['main']['temp_min'] as num).toDouble(),
//           'icon': item['weather'][0]['icon'],
//           'condition': item['weather'][0]['main'],
//         };
//       } else {
//         // Update max/min across all entries for that day
//         final existing = dailyMap[dayKey]!;
//         final newMax = (item['main']['temp_max'] as num).toDouble();
//         final newMin = (item['main']['temp_min'] as num).toDouble();
//         if (newMax > (existing['temp_max'] as double)) {
//           existing['temp_max'] = newMax;
//         }
//         if (newMin < (existing['temp_min'] as double)) {
//           existing['temp_min'] = newMin;
//         }
//       }
//     }
//
//     setState(() {
//       _forecast = dailyMap.values.take(5).toList();
//     });
//   }
//
//   String _getFarmingTip(String condition, double temp, int humidity) {
//     condition = condition.toLowerCase();
//
//     if (condition.contains('rain') || condition.contains('drizzle')) {
//       return '🌧️ Rain expected — avoid spraying pesticides today. Good time for transplanting seedlings.';
//     } else if (condition.contains('thunderstorm')) {
//       return '⛈️ Thunderstorm alert — keep workers off the field. Secure loose equipment and greenhouse covers.';
//     } else if (condition.contains('snow')) {
//       return '❄️ Snow conditions — protect frost-sensitive crops. Check irrigation pipes for freezing.';
//     } else if (condition.contains('mist') ||
//         condition.contains('fog') ||
//         condition.contains('haze')) {
//       return '🌫️ Low visibility conditions — delay spraying. Watch for fungal disease spread in moist air.';
//     } else if (condition.contains('clear') && temp > 35) {
//       return '☀️ Very hot day — water crops early morning or evening. Avoid fieldwork during peak heat (11am–3pm).';
//     } else if (condition.contains('clear') && temp < 10) {
//       return '🥶 Cold clear night ahead — protect sensitive seedlings from frost. Cover crops if needed.';
//     } else if (condition.contains('clear')) {
//       return '✅ Clear skies — ideal day for spraying fertilizers or pesticides. Early morning is best.';
//     } else if (condition.contains('cloud')) {
//       return '⛅ Cloudy weather — good conditions for field inspection, transplanting, and light irrigation.';
//     } else if (humidity > 80) {
//       return '💧 High humidity — watch out for fungal diseases. Ensure good crop ventilation and reduce irrigation.';
//     } else if (temp > 30) {
//       return '🌡️ Warm day — monitor soil moisture closely. Irrigate in cooler parts of the day.';
//     } else {
//       return '🌱 Monitor crop moisture levels and irrigate if needed. Good day for routine field checks.';
//     }
//   }
//
//   String _dayName(DateTime date) {
//     const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//     final now = DateTime.now();
//
//     if (date.day == now.day && date.month == now.month) return 'Today';
//     if (date.day == now.add(const Duration(days: 1)).day &&
//         date.month == now.add(const Duration(days: 1)).month) {
//       return 'Tomorrow';
//     }
//     return days[date.weekday - 1];
//   }
//
//   IconData _getWeatherIcon(String condition) {
//     condition = condition.toLowerCase();
//     if (condition.contains('rain') || condition.contains('drizzle')) {
//       return Icons.grain;
//     } else if (condition.contains('thunder')) {
//       return Icons.flash_on;
//     } else if (condition.contains('snow')) {
//       return Icons.ac_unit;
//     } else if (condition.contains('cloud')) {
//       return Icons.cloud;
//     } else if (condition.contains('mist') ||
//         condition.contains('fog') ||
//         condition.contains('haze')) {
//       return Icons.blur_on;
//     } else {
//       return Icons.wb_sunny;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           "🌾 Farm Weather",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: Colors.green[700],
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Refresh',
//             onPressed: _loadWeather,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? _buildLoadingState()
//           : _error.isNotEmpty
//           ? _buildErrorState()
//           : _buildWeatherContent(),
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(color: Colors.green),
//           SizedBox(height: 16),
//           Text(
//             "Fetching weather data...",
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           SizedBox(height: 8),
//           Text(
//             "Getting your location 📍",
//             style: TextStyle(fontSize: 13, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.cloud_off, size: 72, color: Colors.grey),
//             const SizedBox(height: 16),
//             const Text(
//               'Unable to load weather',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _error,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.grey, fontSize: 14),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: _loadWeather,
//               icon: const Icon(Icons.refresh),
//               label: const Text("Try Again"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green[700],
//                 foregroundColor: Colors.white,
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildWeatherContent() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // --- Current Weather Card ---
//           _buildCurrentWeatherCard(),
//
//           const SizedBox(height: 16),
//
//           // --- Farming Tip ---
//           _buildFarmingTipCard(),
//
//           const SizedBox(height: 20),
//
//           // --- 5-Day Forecast Header ---
//           const Text(
//             '5-Day Forecast',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 10),
//
//           // --- Forecast List ---
//           ..._forecast.map((day) => _buildForecastCard(day)),
//
//           const SizedBox(height: 20),
//
//           // --- Weather Stats Grid ---
//           _buildStatsGrid(),
//
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCurrentWeatherCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(22),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green[700]!, Colors.teal[600]!],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.4),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // City + Icon Row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on,
//                             color: Colors.white70, size: 16),
//                         const SizedBox(width: 4),
//                         Flexible(
//                           child: Text(
//                             _city,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _condition.toUpperCase(),
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 12,
//                         letterSpacing: 1.2,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (_icon.isNotEmpty)
//                 Image.network(
//                   'https://openweathermap.org/img/wn/$_icon@2x.png',
//                   width: 70,
//                   height: 70,
//                   errorBuilder: (context, error, stackTrace) => Icon(
//                     _getWeatherIcon(_condition),
//                     color: Colors.white,
//                     size: 50,
//                   ),
//                 ),
//             ],
//           ),
//
//           const SizedBox(height: 8),
//
//           // Temperature
//           Text(
//             '${_temp.toStringAsFixed(1)}°C',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 56,
//               fontWeight: FontWeight.w300,
//               height: 1.0,
//             ),
//           ),
//
//           const SizedBox(height: 4),
//           Text(
//             'Feels like ${_feelsLike.toStringAsFixed(1)}°C',
//             style: const TextStyle(color: Colors.white70, fontSize: 14),
//           ),
//
//           const SizedBox(height: 20),
//           const Divider(color: Colors.white24, thickness: 1),
//           const SizedBox(height: 16),
//
//           // Stats Row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _statItem(Icons.water_drop, '$_humidity%', 'Humidity'),
//               _statItem(
//                   Icons.air, '${_windSpeed.toStringAsFixed(1)} km/h', 'Wind'),
//               _statItem(
//                   Icons.cloud, '${_rainChance.toInt()}%', 'Cloud Cover'),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFarmingTipCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       decoration: BoxDecoration(
//         color: Colors.green[50],
//         border: Border.all(color: Colors.green.shade200, width: 1.5),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.green[100],
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child:
//             Icon(Icons.agriculture, color: Colors.green[800], size: 22),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Farming Advisory',
//                   style: TextStyle(
//                     color: Colors.green[900],
//                     fontWeight: FontWeight.bold,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _farmingTip,
//                   style: TextStyle(
//                     color: Colors.green[800],
//                     fontSize: 14,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildForecastCard(Map<String, dynamic> day) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Day name
//           SizedBox(
//             width: 80,
//             child: Text(
//               _dayName(day['date'] as DateTime),
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//
//           // Condition
//           Expanded(
//             child: Row(
//               children: [
//                 if (day['icon'] != null)
//                   Image.network(
//                     'https://openweathermap.org/img/wn/${day['icon']}.png',
//                     width: 36,
//                     height: 36,
//                     errorBuilder: (context, error, stackTrace) => Icon(
//                       _getWeatherIcon(day['condition'] ?? ''),
//                       color: Colors.grey,
//                       size: 24,
//                     ),
//                   ),
//                 const SizedBox(width: 4),
//                 Text(
//                   day['condition'] ?? '',
//                   style: TextStyle(color: Colors.grey[600], fontSize: 13),
//                 ),
//               ],
//             ),
//           ),
//
//           // Temp range
//           Text(
//             '${(day['temp_max'] as double).toStringAsFixed(0)}°  /  ${(day['temp_min'] as double).toStringAsFixed(0)}°',
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatsGrid() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Current Details',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 10),
//         GridView.count(
//           crossAxisCount: 2,
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//           childAspectRatio: 2.0,
//           children: [
//             _buildStatTile(
//               Icons.thermostat,
//               'Feels Like',
//               '${_feelsLike.toStringAsFixed(1)}°C',
//               Colors.orange,
//             ),
//             _buildStatTile(
//               Icons.water_drop,
//               'Humidity',
//               '$_humidity%',
//               Colors.blue,
//             ),
//             _buildStatTile(
//               Icons.air,
//               'Wind Speed',
//               '${_windSpeed.toStringAsFixed(1)} km/h',
//               Colors.teal,
//             ),
//             _buildStatTile(
//               Icons.cloud,
//               'Cloud Cover',
//               '${_rainChance.toInt()}%',
//               Colors.grey,
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStatTile(
//       IconData icon, String label, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color, size: 20),
//           ),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(color: Colors.grey, fontSize: 11),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _statItem(IconData icon, String value, String label) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.white70, size: 22),
//         const SizedBox(height: 6),
//         Text(
//           value,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(color: Colors.white70, fontSize: 11),
//         ),
//       ],
//     );
//   }
// }
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

            // Current weather card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _city,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_temp.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _condition.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            'Feels like ${_feelsLike.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      Image.network(
                        'https://openweathermap.org/img/wn/$_icon@2x.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(Icons.water_drop, '$_humidity%', 'Humidity'),
                      _statItem(Icons.grain, '${_rainChance.toInt()}%', 'Cloud'),
                      _statItem(Icons.air, '${_windSpeed.toStringAsFixed(1)} km/h', 'Wind'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Farming tip card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🌾 Farming Advisory',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _farmingTip,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5-day forecast
            if (_forecast.isNotEmpty) ...[
              const Text(
                '5-Day Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: _forecast.asMap().entries.map((entry) {
                    final i = entry.key;
                    final day = entry.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  _dayName(day['date']),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Image.network(
                                'https://openweathermap.org/img/wn/${day['icon']}.png',
                                width: 36,
                                height: 36,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.wb_sunny,
                                    color: Colors.orange),
                              ),
                              Text(
                                day['condition'],
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                              Text(
                                '${day['temp_max'].toStringAsFixed(0)}° / ${day['temp_min'].toStringAsFixed(0)}°',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (i < _forecast.length - 1)
                          Divider(
                              height: 1,
                              color: Colors.grey.shade200),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 20),
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