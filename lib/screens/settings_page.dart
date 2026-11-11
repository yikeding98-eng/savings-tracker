import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/app_settings.dart';
import '../utils/format.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _targetController;
  late String _currency;
  late bool _reminderEnabled;
  late int _reminderDay;
  late int _reminderHour;
  late int _reminderMinute;
  DateTime? _targetDate;

  static const List<String> _currencyOptions = <String>['¥', r'$', '€', 'Kz', '£'];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final s = AppScope.of(context).settings;
    _targetController =
        TextEditingController(text: s.targetAmount.toStringAsFixed(0));
    _currency = _currencyOptions.contains(s.currency) ? s.currency : '¥';
    _reminderEnabled = s.reminderEnabled;
    _reminderDay = s.reminderDay;
    _reminderHour = s.reminderHour;
    _reminderMinute = s.reminderMinute;
    _targetDate = s.targetDate;
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 30),
      helpText: '想在哪天存到目标？',
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final amount = double.tryParse(_targetController.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目标金额需要大于 0')),
      );
      return;
    }

    if (_reminderEnabled) {
      await state.reminder.requestPermission();
    }

    await state.updateSettings(
      AppSettings(
        targetAmount: amount,
        currency: _currency,
        reminderEnabled: _reminderEnabled,
        reminderDay: _reminderDay,
        reminderHour: _reminderHour,
        reminderMinute: _reminderMinute,
        targetDate: _targetDate,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
  }

  Future<void> _copyData() async {
    final json = await AppScope.of(context).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('数据已复制，可粘贴到备忘录里备份')),
    );
  }

  Future<void> _importData() async {
    final raw =
        (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!mounted) return;
    if (raw.isEmpty) {
      _snack('剪贴板里没有内容，先把之前备份的 JSON 复制过来');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入备份？'),
        content: const Text('导入会用备份覆盖当前的记录和设置，建议先复制一份当前数据。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('导入')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final count = await AppScope.of(context).importJson(raw);
    if (!mounted) return;
    if (count == null) {
      _snack('备份格式不对，请确认复制的是完整 JSON');
      return;
    }
    _syncFromState();
    _snack('已恢复 $count 条记录');
  }

  void _syncFromState() {
    final s = AppScope.of(context).settings;
    setState(() {
      _targetController.text = s.targetAmount.toStringAsFixed(0);
      _currency = _currencyOptions.contains(s.currency) ? s.currency : '¥';
      _reminderEnabled = s.reminderEnabled;
      _reminderDay = s.reminderDay;
      _reminderHour = s.reminderHour;
      _reminderMinute = s.reminderMinute;
      _targetDate = s.targetDate;
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _clearData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空所有数据？'),
        content: const Text('所有存款记录会被删除，且无法恢复。建议先复制备份。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppScope.of(context).clearAll();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _SectionLabel(text: '存款目标', color: scheme.onSurfaceVariant),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '目标金额',
                      border: InputBorder.none,
                      filled: false,
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('目标完成日期', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _targetDate == null ? '未设置（用于计算每月需存多少）' : formatDate(_targetDate!),
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_targetDate != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _targetDate = null),
                          ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    onTap: _pickTargetDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionLabel(text: '提醒', color: scheme.onSurfaceVariant),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                  title: const Text('每月提醒我存钱', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '到点弹出系统通知',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ListTile(
                  enabled: _reminderEnabled,
                  title: const Text('提醒日', style: TextStyle(fontSize: 14)),
                  trailing: Text('每月 $_reminderDay 日'),
                  onTap: _reminderEnabled
                      ? () async {
                          final day = await showModalBottomSheet<int>(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: SizedBox(
                                height: 300,
                                child: GridView.count(
                                  crossAxisCount: 7,
                                  padding: const EdgeInsets.all(12),
                                  children: [
                                    for (var d = 1; d <= 28; d++)
                                      InkWell(
                                        onTap: () => Navigator.pop(ctx, d),
                                        child: Center(
                                          child: Text(
                                            '$d',
                                            style: TextStyle(
                                              fontWeight: d == _reminderDay
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: d == _reminderDay ? scheme.primary : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          if (day != null) setState(() => _reminderDay = day);
                        }
                      : null,
                ),
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ListTile(
                  enabled: _reminderEnabled,
                  title: const Text('提醒时间', style: TextStyle(fontSize: 14)),
                  trailing: Text(formatTime(_reminderHour, _reminderMinute)),
                  onTap: _reminderEnabled ? _pickTime : null,
                ),
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('发一条测试通知', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '确认通知权限和声音是否正常',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  onTap: () async {
                    await state.reminder.requestPermission();
                    await state.reminder.showTestNow();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已发送，留意通知栏')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionLabel(text: '显示', color: scheme.onSurfaceVariant),
          Card(
            child: ListTile(
              title: const Text('货币符号', style: TextStyle(fontSize: 14)),
              trailing: DropdownButton<String>(
                value: _currency,
                underline: const SizedBox.shrink(),
                items: [
                  for (final c in _currencyOptions)
                    DropdownMenuItem<String>(value: c, child: Text(c)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _currency = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionLabel(text: '数据', color: scheme.onSurfaceVariant),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.copy_all_outlined),
                  title: const Text('复制数据（JSON 备份）', style: TextStyle(fontSize: 14)),
                  onTap: _copyData,
                ),
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ListTile(
                  leading: const Icon(Icons.content_paste_outlined),
                  title: const Text('粘贴导入备份', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('换手机或重装后恢复数据', style: TextStyle(fontSize: 11)),
                  onTap: _importData,
                ),
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: scheme.error),
                  title: Text('清空所有数据', style: TextStyle(fontSize: 14, color: scheme.error)),
                  onTap: _clearData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('保存设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          Text(
            '数据只保存在本机，不上传任何服务器。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, letterSpacing: 0.5),
      ),
    );
  }
}
