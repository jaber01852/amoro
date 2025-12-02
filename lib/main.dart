import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'amplifyconfiguration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(MyApp());
}

/// ------------------------------
/// CONFIGURE AMPLIFY
/// ------------------------------
Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(),
    ]);

    await Amplify.configure(amplifyconfig);
    safePrint("✅ Amplify configured");
  } on AmplifyAlreadyConfiguredException {
    safePrint("⚠️ Amplify already configured.");
  } catch (e) {
    safePrint("❌ Amplify error: $e");
  }
}

/// ------------------------------
/// ROOT APP
/// ------------------------------
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      setState(() {
        _isSignedIn = session.isSignedIn;
        _isLoading = false;
      });
    } catch (e) {
      safePrint("Session error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Amoro",
      home: _isSignedIn ? HomeScreen() : AuthScreen(onSignedIn: () {
        setState(() => _isSignedIn = true);
      }),
    );
  }
}

/// ------------------------------
/// AUTH SCREEN (LOGIN + SIGN UP)
/// ------------------------------
class AuthScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  const AuthScreen({required this.onSignedIn});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool showConfirm = false;
  bool loading = false;
  String status = "";

  Future<void> _signUp() async {
    setState(() => loading = true);
    try {
      final result = await Amplify.Auth.signUp(
        username: email.text.trim(),
        password: password.text.trim(),
        options: SignUpOptions(
          userAttributes: {CognitoUserAttributeKey.email: email.text.trim()},
        ),
      );

      if (!result.isSignUpComplete) {
        showConfirm = true;
        status = "📩 Check your email for the confirmation code.";
      }
    } catch (e) {
      status = "❌ Sign-up failed: $e";
    }
    setState(() => loading = false);
  }

  Future<void> _confirmSignUp() async {
    setState(() => loading = true);
    try {
      await Amplify.Auth.confirmSignUp(
        username: email.text.trim(),
        confirmationCode: confirm.text.trim(),
      );

      await _signIn();
    } catch (e) {
      status = "❌ Confirmation failed: $e";
    }
    setState(() => loading = false);
  }

  Future<void> _signIn() async {
    setState(() => loading = true);
    try {
      final result = await Amplify.Auth.signIn(
        username: email.text.trim(),
        password: password.text.trim(),
      );

      if (result.isSignedIn) {
        widget.onSignedIn();
      }
    } catch (e) {
      status = "❌ Sign-in failed: $e";
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Amoro Auth")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
                  TextField(
                    controller: password,
                    decoration: InputDecoration(labelText: "Password"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),

                  if (!showConfirm) ...[
                    ElevatedButton(onPressed: loading ? null : _signUp, child: Text("Sign Up")),
                    ElevatedButton(onPressed: loading ? null : _signIn, child: Text("Sign In")),
                  ],

                  if (showConfirm) ...[
                    TextField(controller: confirm, decoration: InputDecoration(labelText: "Confirmation Code")),
                    ElevatedButton(onPressed: loading ? null : _confirmSignUp, child: Text("Confirm Email")),
                  ],

                  const SizedBox(height: 20),
                  Text(status, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),

          if (loading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
        ],
      ),
    );
  }
}

/// ------------------------------
/// HOME SCREEN (BUTTON SHOWS HERE!!)
/// ------------------------------
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool creating = false;
  String message = "";

  Future<void> _createTestProfile() async {
    setState(() => creating = true);

    final user = await Amplify.Auth.getCurrentUser();

    final request = GraphQLRequest<String>(
      document: '''
        mutation CreateUserProfile {
          createUserProfile(input: {
            id: "${user.userId}",
            name: "Test User",
            age: 21,
            bio: "This is a test profile",
            gender: "male"
          }) { id name }
        }
      ''',
    );

    try {
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isEmpty) {
        message = "🎉 Profile created!";
      } else {
        message = "❌ GraphQL error: ${response.errors.first.message}";
      }
    } catch (e) {
      message = "❌ Mutation failed: $e";
    }

    setState(() => creating = false);
  }

  Future<void> _signOut() async {
    await Amplify.Auth.signOut();
    runApp(MyApp());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome to Amoro")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🎉 You are signed in!"),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: creating ? null : _createTestProfile,
              child: Text("Create Test User Profile"),
            ),
            const SizedBox(height: 10),

            Text(message),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _signOut,
              child: Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}
