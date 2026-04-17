import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Handle Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        // 2. Extract User Data
        final user = snapshot.data;
        final String displayName = user?.displayName ?? "Farmer";
        final String? photoUrl = user?.photoURL;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dynamic Greeting Text
            Expanded(
              child: Text(
                "Good Morning, $displayName 👋",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Action Icons and Profile Picture
            Row(
              children: [
                const Icon(Icons.notifications_none, color: Colors.green),
                const SizedBox(width: 12),

                // Dynamic Profile Image
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/images/farmer.png') as ImageProvider,
                ),
              ],
            )
          ],
        );
      },
    );
  }
}