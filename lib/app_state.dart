import 'package:flutter/foundation.dart';

import 'models/app_settings.dart';
import 'models/deposit.dart';
import 'services/reminder_service.dart';
import 'services/storage.dart';
import 'services/widget_bridge.dart';

class AppState extends ChangeNotifier {
  AppState({required this.storage, required this.reminder});

  final Storage storage;
  final ReminderService reminder;
  final WidgetBridge widgetBridge = WidgetBridge();

  bool _loaded = false;
  bool get loaded => _loaded;

  List<Deposit> _deposits = <Deposit>[];
  List<Deposit> get deposits => List<Deposit>.unmodifiable(_deposits);

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  String? nextReminderText;

  double get balance => _deposits.fold(0.0, (sum, d) => sum + d.amount);

  double get remaining {
    final value = _settings.targetAmount - balance;
    return value < 0 ? 0 : value;
  }

  double get progress {
    if (_settings.targetAmount <= 0) return 0;
    final v = balance / _settings.targetAmount;
    return v < 0 ? 0 : (v > 1 ? 1 : v);
  }

  /// 距离目标日期还需要的月数，用于算「每月要存多少」
  int get monthsLeft {
    final target = _settings.targetDate;
    if (target == null) return 0;
    final now = DateTime.now();
    final months = (target.year - now.year) * 12 + target.month - now.month;
    return months < 0 ? 0 : months;
  }

  double get monthlyRequired {
    final target = _settings.targetDate;
    if (target == null) return 0;
    final months = monthsLeft;
    if (months <= 0) return remaining;
    return remaining / months;
  }

  double get depositedThisMonth {
    final now = DateTime.now();
    return _deposits
        .where((d) => d.amount > 0 && d.date.year == now.year && d.date.month == now.month)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double get withdrawThisMonth {
    final now = DateTime.now();
    return _deposits
        .where((d) => d.amount < 0 && d.date.year == now.year && d.date.month == now.month)
        .fold(0.0, (sum, d) => sum + d.amount.abs());
  }

  Future<void> load() async {
    final (deposits, settings) = await storage.load();
    _deposits = deposits;
    _settings = settings;
    _loaded = true;
    notifyListeners();
    await rescheduleReminder();
  }

  Future<void> addDeposit(Deposit deposit) async {
    _deposits = <Deposit>[..._deposits, deposit]..sort((a, b) => b.date.compareTo(a.date));
    await storage.saveDeposits(_deposits);
    notifyListeners();
    await _reschedule();
  }

  Future<void> deleteDeposit(String id) async {
    _deposits = _deposits.where((d) => d.id != id).toList();
    await storage.saveDeposits(_deposits);
    notifyListeners();
    await _reschedule();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await storage.saveSettings(_settings);
    notifyListeners();
    await _reschedule();
  }

  Future<void> clearAll() async {
    _deposits = <Deposit>[];
    await storage.clearAll();
    notifyListeners();
    await _reschedule();
  }

  Future<String> exportJson() => storage.exportJson(_deposits, _settings);

  /// 从剪贴板里的 JSON 备份恢复。格式不对返回 null，成功返回恢复的记录条数。
  Future<int?> importJson(String raw) async {
    final result = await storage.importJson(raw);
    if (result == null) return null;
    final (deposits, settings) = result;
    _deposits = deposits;
    _settings = settings;
    notifyListeners();
    await _reschedule();
    return deposits.length;
  }

  Future<void> rescheduleReminder() => _reschedule();

  Future<void> _reschedule() async {
    try {
      await reminder.scheduleMonthly(
        enabled: _settings.reminderEnabled,
        day: _settings.reminderDay,
        hour: _settings.reminderHour,
        minute: _settings.reminderMinute,
        currency: _settings.currency,
        remaining: remaining,
      );
      nextReminderText = await reminder.nextScheduleText(
        enabled: _settings.reminderEnabled,
        day: _settings.reminderDay,
        hour: _settings.reminderHour,
        minute: _settings.reminderMinute,
      );
    } catch (e) {
      debugPrint('reminder schedule failed: $e');
    }

    await widgetBridge.sync(
      balance: balance,
      settings: _settings,
      remaining: remaining,
      progress: progress,
      depositedThisMonth: depositedThisMonth,
      nextReminderText: nextReminderText,
    );

    notifyListeners();
  }
}
