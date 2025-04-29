// totp_service.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TOTPService {
  static const String _secretKey = '2fa_secret_key';
  static const String _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  static const String _is2FAEnabledKey = '2fa_enabled_status';

  // Generate a new random secret key
  static String generateSecretKey() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }

    String result = '';
    for (var byte in bytes) {
      result += _charset[byte % _charset.length];
    }
    return result.substring(0, 32);
  }

  static int generateCode(String secret) {
    return OTP.generateTOTPCode(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  static bool verifyCode(String secret, String code) {
    final generatedCode = generateCode(secret);
    return generatedCode == code;
  }

  static Future<void> saveSecret(String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secretKey, secret);
  }

  static Future<String?> getSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_secretKey);
  }

  static Future<void> removeSecret() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_secretKey);
  }

  static Future<void> set2FAStatus(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_is2FAEnabledKey, enabled);
  }

  static Future<bool> is2FAEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_is2FAEnabledKey) ?? false;
  }
}
