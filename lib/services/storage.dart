import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/deposit.dart';

class Storage {
  static const _kDeposits = 'deposits_v1';
  static const _kSettings = 'settings_v1';

  Future<(List<Deposit>, AppSettings)> load() async {
    final sp = await SharedPreferences.getInstance();
    final rawDeposits = sp.getString(_kDeposits);
    final rawSettings = sp.getString(_kSettings);

    final deposits = <Deposit>[];
    if (rawDeposits != null && rawDeposits.isNotEmpty) {
      final decoded = jsonDecode(rawDeposits);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            deposits.add(Deposit.fromJson(item));
          }
        }
      }
    }

    var settings = const AppSettings();
    if (rawSettings != null && rawSettings.isNotEmpty) {
      final decoded = jsonDecode(rawSettings);
      if (decoded is Map<String, dynamic>) {
        settings = AppSettings.fromJson(decoded);
      }
    }

    deposits.sort((a, b) => b.date.compareTo(a.date));
    return (deposits, settings);
  }

  Future<void> saveDeposits(List<Deposit> deposits) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDeposits, jsonEncode(deposits.map((e) => e.toJson()).toList()));
  }

  Future<void> saveSettings(AppSettings settings) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  Future<String> exportJson(List<Deposit> deposits, AppSettings settings) async {
    return const JsonEncoder.withIndent('  ').convert({
      'settings': settings.toJson(),
      'deposits': deposits.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kDeposits);
    await sp.remove(_kSettings);
  }
}
