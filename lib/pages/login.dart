import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/notification_service.dart';
import '../core/user_service.dart';
import '../provider/login_data.dart';
import '../provider/online_status_provider.dart';
import 'home.dart';
import 'two_fa_setup_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final PageController _pageController = PageController();
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final bool _isGoogleSigningIn = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    prefsData();
    _checkExistingSession();
  }

  void prefsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('userData');

      if (userData != null && userData.isNotEmpty) {
        final List<dynamic> userDataMap = jsonDecode(userData);
        final String? accessToken = userDataMap[0]['token'];

        if (accessToken != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        }
      }
    } catch (e) {
      print("Error checking preferences: $e");
    }
  }

  Future<void> _checkExistingSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('userData')) {
      final String? userData = prefs.getString('userData');
      if (userData != null && userData.isNotEmpty) {
        try {
          final List<dynamic> userDataMap = jsonDecode(userData);
          if (userDataMap.isNotEmpty && userDataMap[0]['id'] != null) {
            final String userId = userDataMap[0]['id'].toString();
            await UserService.ensureUserDocument(userId, online: false);
          }
          // ignore: empty_catches
        } catch (e) {}
      }
    }
  }

  Future<void> signInWithSocialProvider({
    required String provider, // e.g., 'google', 'github'
    required String accessToken, // Access token from the provider
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Center(child: Text('Processing Social Login...')),
        backgroundColor: Colors.green.shade300,
      ),
    );

    try {
      final ApiClient apiClient = ApiClient();
      final dynamic res = await apiClient.socialLogin(provider, accessToken);

      if (res is List && res.isNotEmpty) {
        final userInfo = res[0];
        if (userInfo is Map<String, dynamic>) {
          final String? accessToken = userInfo['token'];
          final user = userInfo['user'];

          if (accessToken != null && user != null) {
            // Save user data to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userData', jsonEncode(res));

            // Update app state with user info
            await Provider.of<LoginData>(
              context,
              listen: false,
            ).setUserInfo(accessToken);

            // Set user as online in Firebase
            final String userId = user['id'].toString();

            try {
              await UserService.ensureUserDocument(userId, online: true);
              await Provider.of<OnlineStatusProvider>(
                context,
                listen: false,
              ).setUserId(userId);
              await Provider.of<OnlineStatusProvider>(
                context,
                listen: false,
              ).updateOnlineStatus(true);
              await NotificationService().initialize();
              // ignore: empty_catches
            } catch (e) {}

            // Navigate to the home screen
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Home()),
                (Route<dynamic> route) => false,
              );
            }
          } else {
            throw Exception('Something went wrong');
          }
        } else {
          throw Exception('User data is not in expected format');
        }
      } else {
        throw Exception('Unexpected API response format');
      }
    } catch (e) {
      // print("Social Login failed: ${e.toString()}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Social Login failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Step 1: Trigger Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            Platform.isAndroid
                ? '894667091574-jk2et7oqdqak2vq99s1ta7j5agobhq9k.apps.googleusercontent.com'
                : null,
        clientId:
            Platform.isIOS
                ? '894667091574-rtqhd0bnp3k3forck3au25nmhu1jqjhu.apps.googleusercontent.com'
                : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In failed: User canceled the sign-in.');
      }

      // Step 2: Get authentication details from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // IMPORTANT: Send the accessToken, not the idToken for Socialite
      if (googleAuth.accessToken == null) {
        throw Exception('Google Sign-In failed: No access token received.');
      }

      // Step 3: Call the social login method with the access token
      await signInWithSocialProvider(
        provider: 'google',
        accessToken:
            googleAuth.accessToken!, // Use accessToken instead of idToken
      );
    } catch (e) {
      print('Google Sign In failed: ${e.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign In failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  Future<void> loginUsers() async {
    if (_loginFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Center(child: Text('Processing Login...')),
          backgroundColor: Colors.green.shade300,
        ),
      );

      try {
        final ApiClient apiClient = ApiClient();
        final dynamic res = await apiClient.login(
          emailController.text,
          passwordController.text,
        );

        if (res is List && res.isNotEmpty) {
          final userInfo = res[0];
          if (userInfo is Map<String, dynamic>) {
            final String? accessToken = userInfo['token'];
            final user = userInfo['user'];
            // print(user);
            if (accessToken != null && user != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userData', jsonEncode(res));

              if (user['has_2fa_enabled'] != '1') {
                print(user['has_2fa_enabled']);
                // Show 2FA verification dialog
                final verified = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => TwoFADialog(),
                );

                if (verified != true) {
                  throw Exception('2FA verification failed');
                }
              }

              await Provider.of<LoginData>(
                context,
                listen: false,
              ).setUserInfo(accessToken);

              final String userId = user['id'].toString();

              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );

                await UserService.ensureUserDocument(userId, online: true);
                await Provider.of<OnlineStatusProvider>(
                  context,
                  listen: false,
                ).setUserId(userId);
                await Provider.of<OnlineStatusProvider>(
                  context,
                  listen: false,
                ).updateOnlineStatus(true);
                await NotificationService().initialize();

                // ignore: empty_catches
              } catch (e) {}

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Home()),
                  (Route<dynamic> route) => false,
                );
              }
            } else {
              throw Exception('Something went wrong');
            }
          } else {
            throw Exception('User data is not in expected format');
          }
        } else {
          throw Exception('Unexpected API response format');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: Colors.red.shade300,
            ),
          );
        }
      }
    }
  }

  Future<void> signupUsers() async {
    if (_signupFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Center(child: Text('Processing Sign Up...')),
          backgroundColor: Colors.blue.shade300,
        ),
      );

      try {
        final ApiClient apiClient = ApiClient();
        final dynamic res = await apiClient.addUser(
          firstnameController.text,
          lastnameController.text,
          emailController.text,
          passwordController.text,
          confirmPasswordController.text,
        );

        if (res != null && res['token'] != null) {
          final String accessToken = res['token'];
          final String userId = res['id'].toString();
          if (res['has_2fa_enabled'] != '1') {
            // Show 2FA verification dialog
            final verified = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => TwoFADialog(),
            );

            if (verified != true) {
              throw Exception('2FA verification failed');
            }
          }
          await Provider.of<LoginData>(
            context,
            listen: false,
          ).setUserInfo(accessToken);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created successfully!'),
              backgroundColor: Colors.green.shade300,
            ),
          );
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );

            await UserService.ensureUserDocument(userId, online: true);
            await Provider.of<OnlineStatusProvider>(
              context,
              listen: false,
            ).setUserId(userId);
            await Provider.of<OnlineStatusProvider>(
              context,
              listen: false,
            ).updateOnlineStatus(true);
            await NotificationService().initialize();
            // ignore: empty_catches
          } catch (e) {}

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        } else {
          throw Exception(res['message'] ?? 'Signup failed: Unknown error');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  Widget buildLoginPage() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Image(image: AssetImage('assets/logo.png'), width: 150),
          ),
          const SizedBox(height: 30),
          const Text(
            'Welcome to',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Smart Task App',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          Form(
            key: _loginFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: loginUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 63, 113),
                  ),
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGoogleSigningIn ? null : signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/google_logo.png', height: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSignUpPage() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Image(image: AssetImage('assets/logo.png'), width: 150),
          ),
          const SizedBox(height: 30),
          const Text(
            'Welcome to',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Smart Task App',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          const Text(
            'Sign Up',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Form(
            key: _signupFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: firstnameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: lastnameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: _validatePassword,
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: signupUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 63, 113),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGoogleSigningIn ? null : signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/google_logo.png', height: 24),

                        const Text(
                          'Sign in with Google',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [buildLoginPage(), buildSignUpPage()],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter an email';
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value) ? null : 'Please enter a valid email';
  }

  String? _validatePassword(String? value) {
    return (value == null || value.isEmpty) ? 'Please enter password' : null;
  }

  String? _validateConfirmPassword(String? value) {
    return (value != passwordController.text) ? 'Passwords do not match' : null;
  }

  String? _validateName(String? value) {
    return (value == null || value.isEmpty) ? 'Please enter full name' : null;
  }
}

// Add this dialog widget in the same file or a new one
class TwoFADialog extends StatelessWidget {
  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Two-Factor Authentication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the 6-digit code from your authenticator app'),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Verify the code
            final apiClient = ApiClient();
            final prefs = await SharedPreferences.getInstance();
            final userData = prefs.getString('userData');

            final token = jsonDecode(userData!)[0]['token'];

            final response = await apiClient.verify2FA(
              token,
              _codeController.text,
            );

            if (response['success'] == true) {
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Invalid code')));
            }
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
