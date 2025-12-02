import 'package:amplify_flutter/amplify_flutter.dart';

class UserProfileService {
  Future<void> createUserProfile({
    required String name,
    required int age,
    required String gender,
    String? bio,
  }) async {
    // 1️⃣ Get signed-in user ID (owner)
    final user = await Amplify.Auth.getCurrentUser();
    final ownerId = user.userId;

    // 2️⃣ Make GraphQL mutation
    const String mutation = r'''
      mutation CreateUserProfile($input: CreateUserProfileInput!) {
        createUserProfile(input: $input) {
          id
          owner
          name
          age
          gender
          bio
        }
      }
    ''';

    final Map<String, dynamic> variables = {
      "input": {
        "owner": ownerId,       // REQUIRED FIELD
        "name": name,
        "age": age,
        "gender": gender,
        "bio": bio,
      }
    };

    final request = GraphQLRequest<String>(
      document: mutation,
      variables: variables,
    );

    final response = await Amplify.API.mutate(request: request).response;

    if (response.errors.isNotEmpty) {
      throw response.errors.first.message;
    }
  }
}
