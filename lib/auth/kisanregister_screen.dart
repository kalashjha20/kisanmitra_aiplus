import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

class KisanRegisterScreen extends StatelessWidget {
  const KisanRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final String googleClientId =
        dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

    final theme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF1B44C)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF1B44C),
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D3A27), Color(0xFF1B2418)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B4D34)
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'REGISTER',
                        style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/images/leaf.png',
                        height: 120,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Join KisanMitra AI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'किसानमित्र ए.आई. से जुड़ें',
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 10),

                      RegisterView(
                        subtitleBuilder: (context, action) =>
                        const SizedBox.shrink(),
                        footerBuilder: (context, action) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Center(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                child: const Text(
                                    "Already have an account? Log In"),
                              ),
                            ),
                          );
                        },
                        providers: [
                          EmailAuthProvider(),
                          GoogleProvider(
                            clientId: googleClientId, // ✅ fixed
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}