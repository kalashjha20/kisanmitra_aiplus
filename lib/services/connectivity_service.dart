import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityService {

  static Future<bool> hasInternet() async {
    try {
      debugPrint("🔍 Checking internet connection...");
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      debugPrint(connected ? "✅ Internet available" : "❌ No internet");
      return connected;

    } catch (e) {
      debugPrint("❌ Internet check failed: $e");
      return false;
    }
  }
}