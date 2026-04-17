import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {

  String locationName = "Loading...";
  double temperature = 0;
  String description = "";
  int humidity = 0;
  double windSpeed = 0;
  int rainChance = 0;
  bool showRainAlert = false;

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    refreshTimer = Timer.periodic(
      const Duration(minutes: 30),
          (timer) => _loadWeather(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() {
        locationName = "Location Permission Denied";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);

    final place = placemarks.first;

    final data = await WeatherService.fetchWeather(
        position.latitude, position.longitude);

    setState(() {
      locationName =
      "${place.subLocality ?? place.locality}, ${place.administrativeArea}";
      temperature = data['main']['temp'];
      description = data['weather'][0]['main'];
      humidity = data['main']['humidity'];
      windSpeed = data['wind']['speed'];
      rainChance = data['clouds']['all'];
      showRainAlert = rainChance > 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        if (showRainAlert)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "⚠ Heavy rain possible. Avoid spraying today.",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationName,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                "${temperature.toStringAsFixed(1)}°C | $description",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem("Humidity", "$humidity%"),
                  _infoItem("Rain", "$rainChance%"),
                  _infoItem("Wind", "${windSpeed.toStringAsFixed(1)} km/h"),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}