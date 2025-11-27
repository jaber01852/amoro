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

Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final api = AmplifyAPI();

    await Amplify.addPlugins([auth, api]);
    await Amplify.configure(amplifyconfig);
    safePrint('✅ Amplify configured successfully');
  } on AmplifyAlreadyConfiguredException {
    safePrint('⚠️ Amplify was already configured.');
  } catch (e) {
    safePrint('❌ Error configuring Amplify: $e');
  }
}

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
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      setState(() {
        _isSignedIn = session.isSignedIn;
        _isLoading = false;
      });
    } catch (e) {
      safePrint('Session check error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSignedIn() => setState(() => _isSignedIn = true);
  void _onSignedOut() => setState(() => _isSignedIn = false);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Amoro',
      home: _isSignedIn ? HomeScreen(onSignOut: _onSignedOut) : AuthScreen(onSignedIn: _onSignedIn),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  const AuthScreen({required this.onSignedIn});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmCodeController = TextEditingController();
  final newPasswordController = TextEditingController();

  String status = '';
  bool showConfirmation = false;
  bool showReset = false;
  bool _isLoading = false;

  Future<void> _withLoading(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    await _withLoading(() async {
      try {
        final result = await Amplify.Auth.signUp(
          username: emailController.text.trim(),
          password: passwordController.text.trim(),
          options: SignUpOptions(
            userAttributes: {
              CognitoUserAttributeKey.email: emailController.text.trim(),
            },
          ),
        );

        if (result.isSignUpComplete) {
          setState(() => status = '✅ Sign-up complete, please sign in.');
        } else {
          setState(() {
            showConfirmation = true;
            status = '📩 Confirmation code sent to your email.';
          });
        }
      } catch (e) {
        setState(() => status = '❌ Sign-up failed: $e');
      }
    });
  }

  Future<void> _confirmSignUp() async {
    await _withLoading(() async {
      try {
        final result = await Amplify.Auth.confirmSignUp(
          username: emailController.text.trim(),
          confirmationCode: confirmCodeController.text.trim(),
        );

        if (result.isSignUpComplete) {
          await _signIn(); // Auto sign-in
        } else {
          setState(() => status = '⚠️ Confirmation not complete yet.');
        }
      } catch (e) {
        setState(() => status = '❌ Confirmation failed: $e');
      }
    });
  }

  Future<void> _resendCode() async {
    await _withLoading(() async {
      try {
        await Amplify.Auth.resendSignUpCode(
          username: emailController.text.trim(),
        );
        setState(() => status = '📨 A new confirmation code has been sent!');
      } catch (e) {
        setState(() => status = '❌ Failed to resend code: $e');
      }
    });
  }

  Future<void> _signIn() async {
    await _withLoading(() async {
      try {
        final result = await Amplify.Auth.signIn(
          username: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (result.isSignedIn) {
          widget.onSignedIn();
        } else {
          setState(() => status = '⚠️ Sign-in not complete.');
        }
      } catch (e) {
        setState(() => status = '❌ Sign-in failed: $e');
      }
    });
  }

  Future<void> _forgotPassword() async {
    await _withLoading(() async {
      try {
        await Amplify.Auth.resetPassword(
          username: emailController.text.trim(),
        );
        setState(() {
          showReset = true;
          status = '📩 Reset code sent to your email.';
        });
      } catch (e) {
        setState(() => status = '❌ Failed to send reset code: $e');
      }
    });
  }

  Future<void> _confirmForgotPassword() async {
    await _withLoading(() async {
      try {
        await Amplify.Auth.confirmResetPassword(
          username: emailController.text.trim(),
          newPassword: newPasswordController.text.trim(),
          confirmationCode: confirmCodeController.text.trim(),
        );
        setState(() {
          showReset = false;
          status = '✅ Password reset successful. Please sign in.';
        });
      } catch (e) {
        setState(() => status = '❌ Password reset failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Amoro Auth')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  if (!showConfirmation && !showReset) ...[
                    ElevatedButton(onPressed: _isLoading ? null : _signUp, child: const Text('Sign Up')),
                    ElevatedButton(onPressed: _isLoading ? null : _signIn, child: const Text('Sign In')),
                    TextButton(onPressed: _isLoading ? null : _forgotPassword, child: const Text('Forgot Password?')),
                  ],
                  if (showConfirmation) ...[
                    TextField(
                      controller: confirmCodeController,
                      decoration: const InputDecoration(labelText: 'Confirmation Code'),
                    ),
                    ElevatedButton(onPressed: _isLoading ? null : _confirmSignUp, child: const Text('Confirm Email')),
                    TextButton(onPressed: _isLoading ? null : _resendCode, child: const Text('Resend Confirmation Code')),
                  ],
                  if (showReset) ...[
                    TextField(
                      controller: confirmCodeController,
                      decoration: const InputDecoration(labelText: 'Reset Code'),
                    ),
                    TextField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                    ),
                    ElevatedButton(onPressed: _isLoading ? null : _confirmForgotPassword, child: const Text('Confirm Reset')),
                  ],
                  const SizedBox(height: 20),
                  Text(status, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),

        // === LOADING OVERLAY ===
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  final VoidCallback onSignOut;
  const HomeScreen({required this.onSignOut});

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      onSignOut();
    } catch (e) {
      safePrint('❌ Sign-out failed: $e');
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
            ElevatedButton(onPressed: _signOut, child: const Text('Sign Out')),
          ],
        ),
      ),
    );
  }
}
