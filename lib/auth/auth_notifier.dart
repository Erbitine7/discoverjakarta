import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthNotifier extends ChangeNotifier {
  static const _tokenKey = 'admin_token';

  String? _token;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  String? get token => _token;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    notifyListeners();
  }

  Future<void> setToken(String? value) async {
    _token = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
    notifyListeners();
  }
}
