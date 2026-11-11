import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/app_settings.dart';

/// 把「当前存款 / 目标 / 进度」写进 App Group，供 iOS 主屏幕小组件读取。
///
/// 小组件是独立的 WidgetKit 扩展，只能通过 App Group 的 UserDefaults 共享数据。
/// App Group 需要付费开发者账号（$99/年）签名才有权限；免费 Apple ID 侧载拿不到，
/// 此时写入会失败，这里静默忽略，不影响 App 本身。
class WidgetBridge {
  static const String appGroupId = 'group.com.personal.savingsTracker';
  static const String widgetName = 'SavingsWidget';
  static const String snapshotKey = 'savings_snapshot';

  bool _ready = false;

  bool get _supported => !kIsWeb && Platform.isIOS;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await HomeWidget.setAppGroupId(appGroupId);
    _ready = true;
  }

  /// 数据一变就调用：写快照 + 让系统刷新小组件
  Future<void> sync({
    required double balance,
    required AppSettings settings,
    required double remaining,
    required double progress,
    required double depositedThisMonth,
    required String? nextReminderText,
  }) async {
    if (!_supported) return;
    try {
      await _ensureReady();
      final snapshot = <String, dynamic>{
        'balance': balance,
        'target': settings.targetAmount,
        'remaining': remaining,
        'progress': progress,
        'currency': settings.currency,
        'monthlySaved': depositedThisMonth,
        'nextReminder': nextReminderText ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await HomeWidget.saveWidgetData<String>(snapshotKey, jsonEncode(snapshot));
      await HomeWidget.updateWidget(iOSName: widgetName);
    } catch (e) {
      // App Group 不可用（免费签名）时静默跳过
      debugPrint('widget sync skipped: $e');
    }
  }
}
