class DateFormatter {
  static const shortDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const fullDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  static const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic'
  ];

  static String getShortDayName(DateTime date) {
    final idx = date.weekday - 1;
    if (idx >= 0 && idx < 7) {
      return shortDays[idx];
    }
    return '';
  }

  static String getFullDayName(DateTime date) {
    final idx = date.weekday - 1;
    if (idx >= 0 && idx < 7) {
      return fullDays[idx];
    }
    return '';
  }

  static String formatFullDate(DateTime date) {
    final dayName = getFullDayName(date);
    final monthName = months[date.month - 1];
    final dayNum = date.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dayName, $dayNum $monthName ${date.year} • $hour:$minute';
  }
}
