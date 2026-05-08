import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/password_history_entry.dart';

class LocalStorageService {
  static const _lastDeviceAddressKey = 'last_device_address';
  static const _lastDeviceNameKey = 'last_device_name';
  static const _passwordHistoryKey = 'password_history';

  Future<void> saveLastDevice({
    required String address,
    required String name,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastDeviceAddressKey, address);
    await preferences.setString(_lastDeviceNameKey, name);
  }

  Future<({String address, String name})?> loadLastDevice() async {
    final preferences = await SharedPreferences.getInstance();
    final address = preferences.getString(_lastDeviceAddressKey);
    if (address == null || address.isEmpty) return null;
    return (
      address: address,
      name: preferences.getString(_lastDeviceNameKey) ?? 'ESP32 Smart Car',
    );
  }

  Future<List<PasswordHistoryEntry>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final rawHistory = preferences.getStringList(_passwordHistoryKey) ?? [];
    return rawHistory
        .map((raw) => PasswordHistoryEntry.fromJson(jsonDecode(raw)))
        .toList();
  }

  Future<void> saveHistory(List<PasswordHistoryEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    final compactEntries = entries.take(25).toList();
    await preferences.setStringList(
      _passwordHistoryKey,
      compactEntries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}
