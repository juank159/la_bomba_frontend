// lib/app/core/utils/date_formatter.dart

import 'package:intl/intl.dart';

/// Utilidad para formatear fechas en zona horaria de Bogotá, Colombia
class DateFormatter {
  // Zona horaria de Bogotá (GMT-5)
  static const _bogotaOffset = Duration(hours: -5);

  /// Convierte una fecha UTC a hora de Bogotá
  static DateTime toLocalTime(DateTime utcDate) {
    // Si la fecha ya está en local, la retornamos
    if (!utcDate.isUtc) {
      return utcDate;
    }
    // Convertir a hora de Bogotá (UTC-5)
    return utcDate.add(_bogotaOffset);
  }

  /// Formatea una fecha como dd/MM/yyyy
  /// Ejemplo: 17/10/2025
  static String formatDate(DateTime date) {
    final localDate = toLocalTime(date);
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(localDate);
  }

  /// Formatea una fecha con hora en formato 12 horas con AM/PM
  /// Ejemplo: 17/10/2025 3:04 PM
  static String formatDateTime(DateTime date) {
    final localDate = toLocalTime(date);
    final formatter = DateFormat('dd/MM/yyyy h:mm a');
    return formatter.format(localDate);
  }

  /// Formatea solo la hora en formato 12 horas con AM/PM
  /// Ejemplo: 3:04 PM
  static String formatTime(DateTime date) {
    final localDate = toLocalTime(date);
    final formatter = DateFormat('h:mm a');
    return formatter.format(localDate);
  }

  /// Formatea una fecha con hora en formato 24 horas
  /// Ejemplo: 17/10/2025 15:04
  static String formatDateTime24h(DateTime date) {
    final localDate = toLocalTime(date);
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(localDate);
  }

  /// Formatea una fecha de forma relativa (Hoy, Ayer, etc)
  /// Ejemplo: "Hoy 3:04 PM", "Ayer 5:30 PM", "15/10/2025"
  static String formatRelative(DateTime date) {
    final localDate = toLocalTime(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(localDate.year, localDate.month, localDate.day);

    if (dateOnly == today) {
      return 'Hoy ${formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'Ayer ${formatTime(date)}';
    } else {
      return formatDate(date);
    }
  }

  /// Formatea una fecha de forma completa y descriptiva
  /// Ejemplo: "Jueves, 17 de octubre de 2025 a las 3:04 PM"
  static String formatFull(DateTime date) {
    final localDate = toLocalTime(date);

    // Nombres de meses en español
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    // Nombres de días en español
    const weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];

    final day = localDate.day;
    final month = months[localDate.month - 1];
    final year = localDate.year;
    final weekday = weekdays[localDate.weekday - 1];
    final time = formatTime(date);

    return '$weekday, $day de $month de $year a las $time';
  }
}
