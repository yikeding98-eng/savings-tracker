class Deposit {
  const Deposit({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;

  /// 正数为存入，负数为取出
  final double amount;
  final DateTime date;
  final String note;

  bool get isDeposit => amount >= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: (json['note'] as String?) ?? '',
      );
}
