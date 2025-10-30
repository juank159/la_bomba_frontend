// lib/features/expenses/presentation/widgets/custom_date_range_picker.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

/// Widget profesional para seleccionar rangos de fechas personalizados
/// Permite seleccionar cualquier rango (ej: Enero 8-20, Mayo 6-14)
class CustomDateRangePicker extends StatefulWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Function(DateTime start, DateTime end, String label) onApplyFilter;
  final VoidCallback onClearFilter;

  const CustomDateRangePicker({
    super.key,
    this.rangeStart,
    this.rangeEnd,
    required this.onApplyFilter,
    required this.onClearFilter,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _rangeStart = widget.rangeStart;
    _rangeEnd = widget.rangeEnd;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;

      if (_rangeStart == null || _rangeEnd != null) {
        // Iniciar nueva selección
        _rangeStart = selectedDay;
        _rangeEnd = null;
      } else if (_rangeStart != null) {
        // Completar el rango
        if (selectedDay.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = selectedDay;
        } else {
          _rangeEnd = selectedDay;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _applyFilter() {
    if (_rangeStart != null && _rangeEnd != null) {
      final startOfDay = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day, 0, 0, 0);
      final endOfDay = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day, 23, 59, 59);

      final formatter = DateFormat('d MMM');
      final label = '${formatter.format(startOfDay)} - ${formatter.format(endOfDay)}';

      widget.onApplyFilter(startOfDay, endOfDay, label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Header
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      ),
                      child: Icon(
                        Icons.date_range,
                        color: colorScheme.primary,
                        size: isSmallScreen ? 18 : 24,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rango Personalizado',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 18,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            'Selecciona inicio y fin',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón de cerrar
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onPrimaryContainer,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      tooltip: 'Cerrar',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 32 : 40,
                        minHeight: isSmallScreen ? 32 : 40,
                      ),
                    ),
                  ],
                ),
                if (_rangeStart != null || _rangeEnd != null) ...[
                  SizedBox(height: isSmallScreen ? 8 : 16),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10 : 16,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inicio',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _rangeStart != null
                                    ? DateFormat('d MMM yyyy').format(_rangeStart!)
                                    : 'No seleccionado',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _rangeStart != null
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Fin',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _rangeEnd != null
                                    ? DateFormat('d MMM yyyy').format(_rangeEnd!)
                                    : 'No seleccionado',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _rangeEnd != null
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Calendar
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
            child: TableCalendar(
              rowHeight: isSmallScreen ? 40 : 48,
              daysOfWeekHeight: isSmallScreen ? 28 : 32,
              firstDay: DateTime(2020),
              lastDay: now,
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: _rangeSelectionMode,

              // Estilo del calendario
              calendarStyle: CalendarStyle(
                // Días fuera del rango permitido
                outsideDaysVisible: false,

                // Día de hoy
                todayDecoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),

                // Días seleccionados
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),

                // Rango seleccionado
                rangeStartDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: colorScheme.primaryContainer.withValues(alpha: 0.3),

                // Días del mes
                defaultDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                ),

                // Días deshabilitados (futuros)
                disabledDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                disabledTextStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),

                // Fines de semana
                weekendDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(
                  color: colorScheme.error.withValues(alpha: 0.7),
                ),
              ),

              // Estilo del header
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ) ?? const TextStyle(),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: colorScheme.primary,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 8),
              ),

              // Estilo de los días de la semana
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: colorScheme.error.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Callbacks
              onDaySelected: (selectedDay, focusedDay) {
                if (!selectedDay.isAfter(now)) {
                  _onDaySelected(selectedDay, focusedDay);
                }
              },

              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },

              // Determinar si un día está seleccionado
              selectedDayPredicate: (day) {
                return isSameDay(_rangeStart, day) || isSameDay(_rangeEnd, day);
              },

              // Deshabilitar días futuros
              enabledDayPredicate: (day) {
                return !day.isAfter(now);
              },
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 12 : 16,
              0,
              isSmallScreen ? 12 : 16,
              isSmallScreen ? 12 : 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearSelection,
                    icon: Icon(Icons.clear, size: isSmallScreen ? 16 : 20),
                    label: Text(
                      'Limpiar',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_rangeStart != null && _rangeEnd != null)
                        ? _applyFilter
                        : null,
                    icon: Icon(Icons.check, size: isSmallScreen ? 16 : 20),
                    label: Text(
                      'Aplicar',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
