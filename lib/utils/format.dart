/// 千分位金额格式化，去掉无意义的 .00 和末尾 0
String formatAmount(num value, {String symbol = '¥'}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    buffer.write(intPart[i]);
    final fromEnd = intPart.length - i - 1;
    if (fromEnd > 0 && fromEnd % 3 == 0) buffer.write(',');
  }

  var decimals = '';
  if (decPart != '00') {
    decimals = '.${decPart.endsWith('0') ? decPart[0] : decPart}';
  }

  return '${negative ? '-' : ''}$symbol${buffer.toString()}$decimals';
}

String twoDigits(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${d.year}-${twoDigits(d.month)}-${twoDigits(d.day)}';

String formatMonth(DateTime d) => '${d.year} 年 ${d.month} 月';

String formatTime(int hour, int minute) => '${twoDigits(hour)}:${twoDigits(minute)}';
