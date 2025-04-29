import 'package:flutter/material.dart';

class SearchProvider extends ChangeNotifier {
  String _query = '';

  String get query => _query;

  void updateQuery(String newQuery) {
    _query = newQuery;
    notifyListeners();
  }
}
