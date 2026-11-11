import 'package:flutter/material.dart';

import '../main.dart';
import '../models/deposit.dart';
import '../utils/format.dart';
import 'home_page.dart' show DepositRow;

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final currency = state.settings.currency;
    final scheme = Theme.of(context).colorScheme;

    if (state.deposits.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text('全部记录', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 46, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('还没有任何记录',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final Map<String, List<Deposit>> groups = <String, List<Deposit>>{};
    for (final d in state.deposits) {
      final key = '${d.date.year}-${d.date.month}';
      groups.putIfAbsent(key, () => <Deposit>[]).add(d);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('全部记录', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${state.deposits.length} 笔',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          for (final entry in groups.entries) ...[
            _MonthHeader(deposits: entry.value, currency: currency),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 58,
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    Dismissible(
                      key: ValueKey<String>(entry.value[i].id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) => state.deleteDeposit(entry.value[i].id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.delete_outline, color: scheme.error),
                      ),
                      child: DepositRow(deposit: entry.value[i], currency: currency),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    return result ?? false;
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.deposits, required this.currency});

  final List<Deposit> deposits;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final depositSum = deposits.where((d) => d.amount > 0).fold(0.0, (s, d) => s + d.amount);
    final withdrawSum =
        deposits.where((d) => d.amount < 0).fold(0.0, (s, d) => s + d.amount.abs());

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(formatMonth(deposits.first.date),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '存入 +${formatAmount(depositSum, symbol: currency)}'
              '${withdrawSum > 0 ? '   取出 -${formatAmount(withdrawSum, symbol: currency)}' : ''}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
