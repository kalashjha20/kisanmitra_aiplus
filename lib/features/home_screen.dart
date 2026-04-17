import 'package:flutter/material.dart';

import 'widgets/greeting_section.dart';
import 'widgets/weather_card.dart';
import 'widgets/search_bar.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/feature_section.dart';
import 'widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),

      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingSection(),
              SizedBox(height: 20),
              WeatherCard(),
              SizedBox(height: 20),
              SearchBarWidget(),
              SizedBox(height: 25),
              QuickActionsGrid(),
              SizedBox(height: 25),
              FeatureSection(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavBar(),
    );
  }
}