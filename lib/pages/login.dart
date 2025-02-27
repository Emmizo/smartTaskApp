import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/pages/home.dart';
import 'package:smart_task_app/provider/login_data.dart';
import 'package:smart_task_app/provider/online_status_provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final PageController _pageController = PageController();
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isGoogleSigningIn = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  // Controllers for text fields
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
  }

  // Check if user data exists in SharedPreferences
  void prefsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString('userData');

      if (userData != null && userData.isNotEmpty) {
        List<dynamic> userDataMap = jsonDecode(userData);
        String? accessToken = userDataMap[0]['token'];

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

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    setState(() => _isGoogleSigningIn = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Center(child: Text('Processing Google Sign In...')),
          backgroundColor: Colors.blue.shade300,
        ),
      );

      // Make sure you're using consistent scopes
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in process
        setState(() => _isGoogleSigningIn = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception("Google Sign-In failed: No ID token received.");
      }

      // Create an instance of ApiClient
      ApiClient apiClient = ApiClient();

      // Call googleLogin using the ApiClient instance
      final response = await apiClient.googleLogin(googleAuth.idToken!);
      print("API response from backend: $response");

      // Process the response similar to your login method
      if (response is List && response.isNotEmpty) {
        var userInfo = response[0];
        if (userInfo is Map<String, dynamic>) {
          String? accessToken = userInfo["token"];
          var user = userInfo["user"];

          if (accessToken != null && user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userData', jsonEncode(response));

            await Provider.of<LoginData>(
              context,
              listen: false,
            ).setUserInfo(accessToken);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          } else {
            throw Exception("Something went wrong");
          }
        } else {
          throw Exception("User data is not in expected format");
        }
      } else {
        throw Exception("Unexpected API response format");
      }
    } catch (e) {
      print("Google Sign In Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign In failed: ${e.toString()}"),
          backgroundColor: Colors.red.shade300,
        ),
      );
    } finally {
      setState(() => _isGoogleSigningIn = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  // User Login
  Future<void> loginUsers() async {
    if (_loginFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Center(child: Text('Processing Login...')),
          backgroundColor: Colors.green.shade300,
        ),
      );

      try {
        ApiClient apiClient = ApiClient();
        dynamic res = await apiClient.login(
          emailController.text,
          passwordController.text,
        );

        if (res is List && res.isNotEmpty) {
          var userInfo = res[0];
          if (userInfo is Map<String, dynamic>) {
            String? accessToken = userInfo["token"];
            var user = userInfo["user"];

            if (accessToken != null && user != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userData', jsonEncode(res));

              await Provider.of<LoginData>(
                context,
                listen: false,
              ).setUserInfo(accessToken);
              await Provider.of<OnlineStatusProvider>(
                context,
                listen: false,
              ).updateOnlineStatus(true);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              );
            } else {
              throw Exception("Something went wrong");
            }
          } else {
            throw Exception("User data is not in expected format");
          }
        } else {
          throw Exception("Unexpected API response format");
        }
      } catch (e) {
        print("Login failed: ${e.toString()}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login failed: ${e.toString()}"),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  // User Sign-Up
  Future<void> signupUsers() async {
    if (_signupFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Center(child: Text('Processing Sign Up...')),
          backgroundColor: Colors.blue.shade300,
        ),
      );

      try {
        ApiClient apiClient = ApiClient();
        dynamic res = await apiClient.addUser(
          firstnameController.text,
          lastnameController.text,
          emailController.text,
          passwordController.text,
          confirmPasswordController.text,
        );

        if (res != null && res['token'] != null) {
          String accessToken = res['token'];
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
          await Provider.of<OnlineStatusProvider>(
            context,
            listen: false,
          ).updateOnlineStatus(true);
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

  // Build Login Page UI
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
            "Welcome to",
            style: TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Smart Task App",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
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
                        "Login",
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
                ElevatedButton(
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
                        "Sign in with Google",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
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

  // Build Sign-Up Page UI
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
            "Welcome to",
            style: TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Smart Task App",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
          const Text(
            "Sign Up",
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
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  child: const Text("Already have an account? Login"),
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

  // Validation Methods
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
