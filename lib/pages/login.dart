import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/pages/home.dart';
import 'package:smart_task_app/provider/login_data.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final PageController _pageController = PageController();
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    prefsData();
  }

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

  Future<void> loginUsers() async {
    if (_loginFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text('Processing Login...')),
          backgroundColor: Colors.green.shade300,
        ),
      );

      try {
        ApiClient apiClient = ApiClient();
        dynamic res = await apiClient.login(
          emailController.text,
          passwordController.text,
        );

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        

        // Check if the response is a List
        if (res is List && res.isNotEmpty) {
          // Get the first item in the list
          var userInfo = res[0];

          if (userInfo is Map<String, dynamic>) {
            // Extract the token and user data
            String? accessToken = userInfo["token"];
            var user = userInfo["user"];

            if (accessToken != null && user != null) {
              // Store the response as is
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userData', jsonEncode(res));

              await Provider.of<LoginData>(
                context,
                listen: false,
              ).setUserInfo(accessToken);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              );
            } else {
              throw Exception("Token or user data missing");
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

  Future<void> signupUsers() async {
    if (_signupFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text('Processing Sign Up...')),
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
        // print(res);

        // Check if the response is valid
        if (res != null && res['token'] != null) {
          String accessToken = res['token'];

          // Store the user data and token
          await Provider.of<LoginData>(
            context,
            listen: false,
          ).setUserInfo(accessToken);

          await Future.delayed(Duration(seconds: 2));
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green.shade300,
            ),
          );

          // Navigate to the home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
        } else {
          throw Exception(res['message'] ?? 'Signup failed: Unknown error');
        }

        _pageController.animateToPage(
          0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [buildLoginPage(), buildSignUpPage()],
      ),
    );
  }

  Widget buildLoginPage() {
    return Padding(
      padding: EdgeInsets.all(28.0),
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
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                  validator: _validatePassword,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: loginUsers,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 3, 63, 113),
                  ),
                  child: SizedBox(
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
                TextButton(
                  onPressed:
                      () => _pageController.animateToPage(
                        1,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                  child: Text("Don't have an account? Sign Up"),
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
      padding: EdgeInsets.all(28.0),
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
          Text(
            "Sign Up",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Form(
            key: _signupFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: firstnameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: lastnameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                  validator: _validatePassword,
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  validator: _validateConfirmPassword,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: signupUsers,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 3, 63, 113),
                    ),
                    child: Center(
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
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                  child: Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ],
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
