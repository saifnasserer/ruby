class DateFormatter {
  static String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String getRelativeDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'النهاردة';
    } else if (dateOnly == yesterday) {
      return 'امبارح';
    } else {
      // Format as "Day DD Month"
      final weekDays = [
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];

      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];

      // Note: DateTime.weekday returns 1 for Monday, 7 for Sunday
      // We need to map it correctly to our array starting with Sunday at index 0
      final dayName = weekDays[date.weekday % 7];
      final monthName = months[date.month - 1];

      return '$dayName ${date.day} $monthName';
    }
  }

  static String formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
