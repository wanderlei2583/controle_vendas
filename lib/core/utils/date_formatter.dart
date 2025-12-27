import 'package:intl/intl.dart';

/// Formatador de datas em formato brasileiro
class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'pt_BR');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'pt_BR');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM', 'pt_BR');

  /// Formata data no formato dd/MM/yyyy
  ///
  /// Exemplo: DateTime(2024, 1, 15) → "15/01/2024"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Formata data e hora no formato dd/MM/yyyy HH:mm
  ///
  /// Exemplo: DateTime(2024, 1, 15, 14, 30) → "15/01/2024 14:30"
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Formata apenas a hora no formato HH:mm
  ///
  /// Exemplo: DateTime(2024, 1, 15, 14, 30) → "14:30"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Alias para formatDate (apenas data, sem hora)
  static String formatDateOnly(DateTime date) => formatDate(date);

  /// Alias para formatTime (apenas hora, sem data)
  static String formatTimeOnly(DateTime date) => formatTime(date);

  /// Formata mês e ano por extenso
  ///
  /// Exemplo: DateTime(2024, 1, 15) → "janeiro 2024"
  static String formatMonthYear(DateTime date) {
    final formatted = _monthYearFormat.format(date);
    // Capitaliza primeira letra
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Formata data curta sem ano (dd/MM)
  ///
  /// Exemplo: DateTime(2024, 1, 15) → "15/01"
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  /// Retorna descrição relativa da data (Hoje, Ontem, etc)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoje';
    } else if (dateOnly == yesterday) {
      return 'Ontem';
    } else if (now.difference(date).inDays < 7) {
      return '${now.difference(date).inDays} dias atrás';
    } else {
      return formatDate(date);
    }
  }

  /// Converte String em formato dd/MM/yyyy para DateTime
  ///
  /// Retorna null se a conversão falhar
  static DateTime? parse(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Retorna o primeiro dia do mês
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Retorna o último dia do mês
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Retorna o primeiro dia da semana (segunda-feira)
  static DateTime firstDayOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Retorna o último dia da semana (domingo)
  static DateTime lastDayOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday, hours: 23, minutes: 59, seconds: 59));
  }
}
