// lib/features/notifications/presentation/pages/calendar_page.dart
//
// Calendario (Grupo F · Calendario del rediseño).
//
// Estructura:
//   - Header: título "Calendario" + navegador de mes (◀ Marzo 2026 ▶).
//   - Card blanca con grid 7×N: L M M J V S D + días numerados,
//     cada día con un pequeño dot de color si tiene eventos.
//   - Leyenda: Vacuna / Chequeo / Celo / Otro con puntos de colores.
//   - Lista de eventos del día seleccionado con hora + título + tag.
//   - FAB "+" con gradient verde para registro rápido (bottom sheet con
//     opciones: Nueva vaca, Registrar celo, Registrar vacuna).
//
// LÓGICA CONECTADA REAL: carga los recordatorios del mes visible con
// ReminderService.listReminders(startDate, endDate).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/reminder_model.dart';
import '../../data/services/reminder_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _service = ReminderService();

  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  List<ReminderModel> _monthReminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      final list = await _service.listReminders(
        startDate: start,
        endDate: end,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _monthReminders = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
    _load();
  }

  List<ReminderModel> _remindersOfDay(DateTime day) {
    return _monthReminders.where((r) {
      final d = r.reminderDate;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _remindersOfDay(_selectedDay);
    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  visibleMonth: _visibleMonth,
                  onBack: () => context.go('/home'),
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                ),
                _CalendarGrid(
                  visibleMonth: _visibleMonth,
                  selectedDay: _selectedDay,
                  remindersOfDay: _remindersOfDay,
                  onSelectDay: (d) => setState(() => _selectedDay = d),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: BovaraColors.primary))
                      : _DayEventsList(
                          selectedDay: _selectedDay,
                          events: selectedEvents,
                        ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 26 + MediaQuery.of(context).padding.bottom,
              child: _QuickAddFab(onTap: _showQuickAddSheet),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickAddSheet(
        onNewCattle: () {
          Navigator.pop(context);
          context.push('/cattle/new');
        },
        onNewReminder: () async {
          Navigator.pop(context);
          // Reusa el modal completo de la pantalla de Tareas
          context.go('/reminders');
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final DateTime visibleMonth;
  final VoidCallback onBack;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _Header({
    required this.visibleMonth,
    required this.onBack,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: BovaraColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: BovaraColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Calendario',
              style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.23,
              ),
            ),
          ),
          // Nav de meses
          _NavArrow(icon: Icons.chevron_left, onTap: onPrev),
          const SizedBox(width: 6),
          SizedBox(
            width: 104,
            child: Text(
              _monthLabel(visibleMonth),
              textAlign: TextAlign.center,
              style: BovaraText.label(
                size: 13,
                color: BovaraColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 6),
          _NavArrow(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${meses[d.month - 1]} ${d.year}';
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 3),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: BovaraColors.textPrimary),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// GRID DE CALENDARIO
// ═════════════════════════════════════════════════════════════════

class _CalendarGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<ReminderModel> Function(DateTime) remindersOfDay;
  final ValueChanged<DateTime> onSelectDay;

  const _CalendarGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.remindersOfDay,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    // Empezamos en LUNES (weekday 1)
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    // Offset para alinear el primer día bajo su weekday.
    // weekday: 1=Lunes ... 7=Domingo → columna 0..6
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    final today = DateTime.now();
    final isThisMonth =
        today.year == visibleMonth.year && today.month == visibleMonth.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 22,
              offset: Offset(0, 8),
              spreadRadius: -14,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header L M M J V S D
            Row(
              children: const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                  .map((c) => Expanded(
                        child: Center(
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: BovaraColors.textDisabled,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: totalCells,
              itemBuilder: (context, i) {
                final dayNum = i - leadingBlanks + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = DateTime(visibleMonth.year, visibleMonth.month, dayNum);
                final isToday = isThisMonth && dayNum == today.day;
                final isSelected = day.year == selectedDay.year &&
                    day.month == selectedDay.month &&
                    day.day == selectedDay.day;
                final events = remindersOfDay(day);

                return _DayCell(
                  day: dayNum,
                  isToday: isToday,
                  isSelected: isSelected,
                  events: events,
                  onTap: () => onSelectDay(day),
                );
              },
            ),
            const SizedBox(height: 10),
            Divider(color: const Color(0xFFF2F3ED), height: 1),
            const SizedBox(height: 10),
            // Leyenda
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: const [
                _LegendDot(color: BovaraColors.info, label: 'Vacuna'),
                _LegendDot(color: BovaraColors.primary, label: 'Chequeo'),
                _LegendDot(color: BovaraColors.celo, label: 'Celo'),
                _LegendDot(color: BovaraColors.warning, label: 'Otro'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final List<ReminderModel> events;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color? bg = isSelected
        ? BovaraColors.primary
        : (isToday ? const Color(0xFFE7F2E9) : null);
    final Color numColor = isSelected
        ? Colors.white
        : (isToday ? BovaraColors.primary : BovaraColors.textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                color: numColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            if (events.isEmpty)
              const SizedBox(width: 5, height: 5)
            else
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : _dotColor(events),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _dotColor(List<ReminderModel> events) {
    // Prioridad de color: celo > vacuna > checkup > otro
    if (events.any((e) => e.type == ReminderType.breeding)) return BovaraColors.celo;
    if (events.any((e) => e.type == ReminderType.vaccine)) return BovaraColors.info;
    if (events.any((e) => e.type == ReminderType.checkup)) return BovaraColors.primary;
    return BovaraColors.warning;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: BovaraText.label(size: 10.5, color: BovaraColors.textMuted)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// LISTA DE EVENTOS DEL DÍA
// ═════════════════════════════════════════════════════════════════

class _DayEventsList extends StatelessWidget {
  final DateTime selectedDay;
  final List<ReminderModel> events;

  const _DayEventsList({required this.selectedDay, required this.events});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _dayLabel(selectedDay),
            style: BovaraText.heading()
                .copyWith(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 11),
          if (events.isEmpty)
            _EmptyDay()
          else
            for (final e in events) ...[
              _EventCard(reminder: e),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  static String _dayLabel(DateTime d) {
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
    ];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}';
  }
}

class _EventCard extends StatelessWidget {
  final ReminderModel reminder;
  const _EventCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(reminder.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700)),
                if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(reminder.description!,
                      style: BovaraText.label(size: 12, color: BovaraColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _bgFor(reminder.type),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              reminder.type.display,
              style: BovaraText.label(size: 10.5, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(ReminderType t) => switch (t) {
        ReminderType.vaccine => BovaraColors.info,
        ReminderType.breeding => BovaraColors.celoSoftText,
        ReminderType.checkup => BovaraColors.primary,
        ReminderType.treatment => BovaraColors.warning,
        _ => BovaraColors.textSecondary,
      };
  Color _bgFor(ReminderType t) => switch (t) {
        ReminderType.vaccine => BovaraColors.infoSoftBg,
        ReminderType.breeding => BovaraColors.celoSoftBg,
        ReminderType.checkup => BovaraColors.primarySoftBg,
        ReminderType.treatment => BovaraColors.warningSoftBg,
        _ => BovaraColors.surfaceAlt,
      };
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Sin eventos este día',
              style: BovaraText.body(size: 13.5, color: BovaraColors.textMuted)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Toca + para programar una tarea',
              style: BovaraText.label(size: 12, color: BovaraColors.textDisabled)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FAB + SHEET DE REGISTRO RÁPIDO
// ═════════════════════════════════════════════════════════════════

class _QuickAddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickAddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.3, -1),
              end: Alignment(0.5, 1),
              colors: [Color(0xFF3DA35D), BovaraColors.primary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: BovaraColors.primary.withValues(alpha: 0.75),
                blurRadius: 30,
                offset: const Offset(0, 14),
                spreadRadius: -10,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _QuickAddSheet extends StatelessWidget {
  final VoidCallback onNewCattle;
  final VoidCallback onNewReminder;

  const _QuickAddSheet({
    required this.onNewCattle,
    required this.onNewReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: BovaraColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Registro rápido',
                    style: BovaraText.heading()
                        .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              _QuickOption(
                icon: Icons.event_available,
                title: 'Nueva tarea',
                subtitle: 'Programa una tarea (vacuna, chequeo, celo)',
                bg: const Color(0xFFF4F8F4),
                border: const Color(0xFFE4EFE6),
                iconBg: const Color(0xFFE7F2E9),
                iconColor: BovaraColors.primary,
                onTap: onNewReminder,
              ),
              const SizedBox(height: 8),
              _QuickOption(
                icon: Icons.pets,
                title: 'Nueva vaca',
                subtitle: 'Alta con foto en 2 minutos',
                bg: const Color(0xFFF4F8F4),
                border: const Color(0xFFE4EFE6),
                iconBg: const Color(0xFFE7F2E9),
                iconColor: BovaraColors.primary,
                onTap: onNewCattle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color bg;
  final Color border;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.border,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: BovaraText.body(size: 13.5, color: BovaraColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: BovaraColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
