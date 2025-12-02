import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  // Get the currently logged-in user's ID
  Future<String> getCurrentUserId() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.userId;
    } catch (e) {
      safePrint("Error getting user ID: $e");
      rethrow;
    }
  }
}
