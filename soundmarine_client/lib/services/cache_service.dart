import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _prefix = 'cache_';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static Future<void> setList(String key, List<Map<String, dynamic>> data) async {
    await _prefs?.setString('$_prefix$key', jsonEncode(data));
  }
  
  static Future<List<Map<String, dynamic>>?> getList(String key) async {
    final String? raw = _prefs?.getString('$_prefix$key');
    if (raw == null) return null;
    return (jsonDecode(raw) as List<dynamic>)
        .map((dynamic e) => e as Map<String, dynamic>)
        .toList();
  }
  
  static Future<void> setMap(String key, Map<String, dynamic> data) async {
    await _prefs?.setString('$_prefix$key', jsonEncode(data));
  }
  
  
  static Future<Map<String, dynamic>?> getMap(String key) async {
    final String? raw = _prefs?.getString('$_prefix$key');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> invalidate(String key) async {
    await _prefs?.remove('$_prefix$key');
  }

  static Future<void> clearAll() async {
    final Set<String> keys = _prefs?.getKeys() ?? {};
    for (final String key in keys.where((String k) => k.startsWith(_prefix))) {
      await _prefs?.remove(key);
    }
  }
}