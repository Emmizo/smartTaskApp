import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/totp_service.dart';

class TwoFASetupScreen extends StatefulWidget {
  const TwoFASetupScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TwoFASetupScreenState createState() => _TwoFASetupScreenState();
}

class _TwoFASetupScreenState extends State<TwoFASetupScreen> {
  String? _secret;
  String? _qrCodeUrl;
  final TextEditingController _codeController = TextEditingController();
  final bool _isVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateSecret();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateSecret() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('userData');
      print(userData);
      if (userData == null || userData.isEmpty) {
        throw Exception('Code not sent');
      }

      // Debug print to see the actual content
      // print('Raw userData: $userData');

      // Safely parse JSON
      final dynamic decodedData = jsonDecode(userData);
      /* print('Decoded data type: ${decodedData.runtimeType}');
    print('Decoded data: $decodedData');
 */
      String token;
      if (decodedData is List) {
        // Handle array response format
        if (decodedData.isEmpty) throw Exception('Empty user data array');
        if (decodedData[0] is! Map) throw Exception('Invalid user data format');
        token = decodedData[0]['token']?.toString() ?? '';
      } else if (decodedData is Map) {
        // Handle object response format
        token = decodedData['token']?.toString() ?? '';
      } else {
        throw Exception(
          'Unexpected user data format: ${decodedData.runtimeType}',
        );
      }

      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // print('Extracted token: $token');

      final response = await ApiClient().generate2FASecret(token);
      print('API Response: $response');

      if (response['success'] == true) {
        setState(() {
          _secret = response['secret']?.toString();
          _qrCodeUrl = response['qr_code']?.toString();
        });

        if (_secret == null) {
          throw Exception('No secret key received from server');
        }

        await TOTPService.saveSecret(_secret!);
      } else {
        final error = response['error']?.toString() ?? 'Unknown error';
        throw Exception(error);
      }
    } catch (e) {
      print('Full error details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_secret == null) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('userData');

      if (userData == null) throw Exception('No user data found');

      final dynamic decodedData = jsonDecode(userData);
      String token;

      if (decodedData is List) {
        token = decodedData[0]['token']?.toString() ?? '';
      } else if (decodedData is Map) {
        token = decodedData['token']?.toString() ?? '';
      } else {
        throw Exception('Unexpected user data format');
      }

      if (token.isEmpty) throw Exception('No authentication token found');

      final response = await ApiClient().verify2FA(token, _codeController.text);

      if (response['success'] == true) {
        await TOTPService.set2FAStatus(true); // Save enabled status locally
        Navigator.pop(context, true); // Return success
      } else {
        throw Exception(response['error']?.toString() ?? 'Invalid code');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup 2FA')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Secure your account with two-factor authentication',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    if (_qrCodeUrl != null) ...[
                      const Text(
                        'Scan this QR code with Google Authenticator:',
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: QrImageView(
                          data: _qrCodeUrl!,
                          size: 200,
                          errorStateBuilder:
                              (cxt, err) =>
                                  const Text('Could not generate QR code'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Or enter this secret manually:'),
                      const SizedBox(height: 10),
                      SelectableText(
                        _secret ?? 'Generating...',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-digit code',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isVerified ? null : _verifyCode,
                      child: Text(_isVerified ? 'Verified!' : 'Verify Code'),
                    ),
                  ],
                ),
              ),
    );
  }
}
