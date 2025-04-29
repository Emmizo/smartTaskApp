import 'dart:io';

class Url {
  static var urlData =
      Platform.isIOS
          ? 'http://localhost:8000/api/v1'
          : 'http://10.0.2.2:8000/api/v1';
  // static const urlData = "https://caritas.infinitexpedions.com/public/api/v1";
}
