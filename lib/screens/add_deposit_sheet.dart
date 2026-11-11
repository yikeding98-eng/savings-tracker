import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/deposit.dart';
import '../utils/format.dart';

Future<void> openAddDepositSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddDepositSheet(),
  );
}

class AddDepositSheet extends StatefulWidget {
  const AddDepositSheet({super.key});

  @override
  State<AddDepositSheet> createState() => _AddDepositSheetState();
}

class _AddDepositSheetState extends State<AddDepositSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  bool _isDeposit = true;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _addQuick(double delta) {
    final current = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final next = current + delta;
    _amountController.text = next.toStringAsFixed(0);
    _amountController.selection =
        TextSelection.collapsed(offset: _amountController.text.length);
    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '选择日期',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final raw = _amountController.text.replaceAll(',', '').trim();
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入金额')),
      );
      return;
    }
    final deposit = Deposit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: _isDeposit ? value : -value,
      date: _date,
      note: _noteController.text.trim(),
    );
    AppScope.of(context).addDeposit(deposit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = AppScope.of(context).settings.currency;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: true, label: Text('存入'), icon: Icon(Icons.south_west)),
                ButtonSegment<bool>(value: false, label: Text('取出'), icon: Icon(Icons.north_east)),
              ],
              selected: <bool>{_isDeposit},
              onSelectionChanged: (s) => setState(() => _isDeposit = s.first),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currency, style: TextStyle(fontSize: 22, color: scheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              children: [
                for (final v in <double>[100, 500, 1000, 5000])
                  ActionChip(
                    label: Text('+${v.toStringAsFixed(0)}'),
                    onPressed: () => _addQuick(v),
                  ),
                ActionChip(
                  label: const Text('清空'),
                  onPressed: () => setState(_amountController.clear),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Text('日期', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    const Spacer(),
                    Text(formatDate(_date), style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '例如：11 月工资存入',
                counterText: '',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_isDeposit ? '确认存入' : '确认取出',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
