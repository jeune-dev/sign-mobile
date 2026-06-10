import 'package:shared_preferences/shared_preferences.dart';

class FormDraftService {
  static Future<void> save(String formKey, Map<String, String> fields) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in fields.entries) {
      await prefs.setString('$formKey.${entry.key}', entry.value);
    }
  }

  static Future<Map<String, String>> restore(
      String formKey, List<String> fieldNames) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, String>{};
    for (final name in fieldNames) {
      final value = prefs.getString('$formKey.$name');
      if (value != null) result[name] = value;
    }
    return result;
  }

  static Future<void> clear(String formKey) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys()
        .where((k) => k.startsWith('$formKey.'))
        .toList();
    for (final key in allKeys) {
      await prefs.remove(key);
    }
  }
}
