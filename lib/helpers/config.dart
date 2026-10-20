import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static const String _defaultUrl = 'http://10.55.70.103:9000/api';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? _defaultUrl;
  }
}
