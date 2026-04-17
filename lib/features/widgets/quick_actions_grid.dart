import 'package:flutter/material.dart';
import '../../../features/scan/scan_screen.dart';
import '../../../features/weather/weather_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: const [
            _QuickCard(
              icon: Icons.camera_alt,
              label: "Diagnose Crop",
            ),
            _QuickCard(
              icon: Icons.cloud,
              label: "Weather Forecast",
            ),
            _QuickCard(
              icon: Icons.show_chart,
              label: "Market Prices",
            ),
            _QuickCard(
              icon: Icons.description,
              label: "Govt Schemes",
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == "Diagnose Crop") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
        }
        else if (label == "Weather Forecast") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeatherScreen()),
          );
        }
        else if (label == "Market Prices") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Market Prices coming soon 🚧")),
          );
        }
        else if (label == "Govt Schemes") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Govt Schemes coming soon 🚧")),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF81C784),
              Color(0xFF4CAF50),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}