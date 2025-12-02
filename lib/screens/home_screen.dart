import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/user_profile_service.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSignOut;
  const HomeScreen({required this.onSignOut, super.key});

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      onSignOut();
    } catch (e) {
      safePrint('❌ Sign-out failed: $e');
    }
  }

  Future<void> _createProfile() async {
    try {
      final service = UserProfileService();

      await service.createUserProfile(
        name: "Test User",
        age: 25,
        gender: "male",
        bio: "This is a test profile",
      );

      safePrint("🎉 Profile created successfully!");
    } catch (e) {
      safePrint("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Amoro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉 You are signed in!'),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _createProfile,
              child: const Text('Create Test User Profile'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _signOut,
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
