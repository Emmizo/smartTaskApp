import 'package:flutter/material.dart';
import '../core/api_client.dart';

class TwoFAVerificationScreen extends StatefulWidget {
  final String authToken;
  final String userId;

  const TwoFAVerificationScreen({
    super.key,
    required this.authToken,
    required this.userId,
  });

  @override
  State<TwoFAVerificationScreen> createState() =>
      _TwoFAVerificationScreenState();
}

class _TwoFAVerificationScreenState extends State<TwoFAVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.verify2FA(
        widget.authToken,
        _otpController.text,
      );

      if (response['message']?.contains('successfully') == true) {
        Navigator.pop(context, true); // Verification successful
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Invalid code')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify 2FA Code')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Enter the 6-digit code from your authenticator app'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _verifyCode,
                  child: const Text('Verify'),
                ),
          ],
        ),
      ),
    );
  }
}
