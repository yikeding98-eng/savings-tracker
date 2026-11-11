import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';
import '../models/deposit.dart';
import '../utils/format.dart';
import '../widgets/progress_ring.dart';
import 'add_deposit_sheet.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final settings = state.settings;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('存款管家', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: '关于',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openAddDepositSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _HeroCard(
            balance: state.balance,
            target: settings.targetAmount,
            currency: settings.currency,
            progress: state.progress,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: '本月已存',
                  value: formatAmount(state.depositedThisMonth, symbol: settings.currency),
                  icon: Icons.trending_up,
                  tint: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: '还差',
                  value: formatAmount(state.remaining, symbol: settings.currency),
                  icon: Icons.flag_outlined,
                  tint: GoldPalette.copper,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (settings.targetDate != null)
            _StatTile(
              label: '按目标日期算，每月需存',
              value: formatAmount(state.monthlyRequired, symbol: settings.currency),
              icon: Icons.calendar_month_outlined,
              tint: scheme.primary,
              wide: true,
            ),
          if (settings.targetDate != null) const SizedBox(height: 12),
          _ReminderCard(
            enabled: settings.reminderEnabled,
            day: settings.reminderDay,
            hour: settings.reminderHour,
            minute: settings.reminderMinute,
            nextText: state.nextReminderText,
            onToggle: (v) => state.updateSettings(settings.copyWith(reminderEnabled: v)),
            onTap: () => _openSettings(context),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('最近记录',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '共 ${state.deposits.length} 笔',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RecentList(deposits: state.deposits.take(5).toList(), currency: settings.currency),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '存款管家',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.savings, size: 42),
      children: const [
        Text('本地记账的小工具：存款余额、目标进度、每月提醒。\n所有数据只存在这台手机里，不会上传。'),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.balance,
    required this.target,
    required this.currency,
    required this.progress,
  });

  final double balance;
  final double target;
  final String currency;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: GoldPalette.goldMid.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GoldPalette.goldLight, GoldPalette.goldMid],
        ),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 96,
            strokeWidth: 8,
            color: GoldPalette.ink,
            trackColor: GoldPalette.ink.withValues(alpha: 0.18),
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: GoldPalette.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前存款',
                    style: TextStyle(
                        color: GoldPalette.ink.withValues(alpha: 0.65),
                        fontSize: 12,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatAmount(balance, symbol: currency),
                    style: const TextStyle(
                      color: GoldPalette.ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '目标 ${formatAmount(target, symbol: currency)}',
                  style: TextStyle(
                      color: GoldPalette.ink.withValues(alpha: 0.65), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: tint),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (!wide) return card;
    return SizedBox(width: double.infinity, child: card);
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.enabled,
    required this.day,
    required this.hour,
    required this.minute,
    required this.nextText,
    required this.onToggle,
    required this.onTap,
  });

  final bool enabled;
  final int day;
  final int hour;
  final int minute;
  final String? nextText;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.alarm, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled
                          ? '每月 $day 日 ${formatTime(hour, minute)} 提醒'
                          : '提醒已关闭',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enabled
                          ? (nextText == null ? '下次提醒待计算' : '下次：$nextText')
                          : '点这里或去设置里打开',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.deposits, required this.currency});

  final List<Deposit> deposits;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (deposits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.savings_outlined, size: 34, color: scheme.onSurfaceVariant),
              const SizedBox(height: 10),
              Text('还没有记录，点右下角「记一笔」开始',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < deposits.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 58, color: scheme.outlineVariant.withValues(alpha: 0.4)),
            DepositRow(deposit: deposits[i], currency: currency),
          ],
        ],
      ),
    );
  }
}

class DepositRow extends StatelessWidget {
  const DepositRow({super.key, required this.deposit, required this.currency});

  final Deposit deposit;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIn = deposit.isDeposit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isIn ? scheme.primary : GoldPalette.copper).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIn ? Icons.south_west : Icons.north_east,
              size: 16,
              color: isIn ? scheme.primary : GoldPalette.copper,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deposit.note.isEmpty ? (isIn ? '存入' : '取出') : deposit.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(formatDate(deposit.date),
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : '-'}${formatAmount(deposit.amount.abs(), symbol: currency)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isIn ? scheme.primary : GoldPalette.copper,
            ),
          ),
        ],
      ),
    );
  }
}
