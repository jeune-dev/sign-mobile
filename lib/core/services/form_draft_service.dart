import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FormDraftService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> save(String formKey, Map<String, String> fields) async {
    for (final entry in fields.entries) {
      await _storage.write(key: '$formKey.${entry.key}', value: entry.value);
    }
  }

  static Future<Map<String, String>> restore(
      String formKey, List<String> fieldNames) async {
    final result = <String, String>{};
    for (final name in fieldNames) {
      final value = await _storage.read(key: '$formKey.$name');
      if (value != null) result[name] = value;
    }
    return result;
  }

  static Future<void> clear(String formKey) async {
    final all = await _storage.readAll();
    for (final key in all.keys.where((k) => k.startsWith('$formKey.'))) {
      await _storage.delete(key: key);
    }
  }
}
