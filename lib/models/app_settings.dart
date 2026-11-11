class AppSettings {
  const AppSettings({
    this.targetAmount = 100000,
    this.currency = '¥',
    this.reminderEnabled = true,
    this.reminderDay = 1,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.targetDate,
  });

  final double targetAmount;
  final String currency;
  final bool reminderEnabled;
  final int reminderDay;
  final int reminderHour;
  final int reminderMinute;
  final DateTime? targetDate;

  AppSettings copyWith({
    double? targetAmount,
    String? currency,
    bool? reminderEnabled,
    int? reminderDay,
    int? reminderHour,
    int? reminderMinute,
    DateTime? targetDate,
    bool clearTargetDate = false,
  }) {
    return AppSettings(
      targetAmount: targetAmount ?? this.targetAmount,
      currency: currency ?? this.currency,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDay: reminderDay ?? this.reminderDay,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'targetAmount': targetAmount,
        'currency': currency,
        'reminderEnabled': reminderEnabled,
        'reminderDay': reminderDay,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'targetDate': targetDate?.toIso8601String(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 100000,
        currency: (json['currency'] as String?) ?? '¥',
        reminderEnabled: (json['reminderEnabled'] as bool?) ?? true,
        reminderDay: (json['reminderDay'] as int?) ?? 1,
        reminderHour: (json['reminderHour'] as int?) ?? 9,
        reminderMinute: (json['reminderMinute'] as int?) ?? 0,
        targetDate: json['targetDate'] == null
            ? null
            : DateTime.tryParse(json['targetDate'] as String),
      );
}
