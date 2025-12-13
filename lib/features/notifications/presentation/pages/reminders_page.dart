// lib/features/notifications/presentation/pages/reminders_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  String currentMonth = 'Octubre 2024';

  // Eventos por día
  final Map<int, List<EventType>> dayEvents = {
    1: [EventType.vacuna, EventType.celo],
    3: [EventType.desparasitacion],
    5: [EventType.parto, EventType.vacuna],
    10: [EventType.desparasitacion, EventType.palpacion, EventType.celo],
    15: [EventType.palpacion, EventType.parto],
    18: [EventType.destete],
    22: [EventType.parto, EventType.vacuna],
    25: [EventType.destete],
    28: [EventType.vacuna],
    30: [EventType.palpacion, EventType.vacuna],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMonthNavigation(),
                    _buildLegend(),
                    _buildCalendar(),
                    _buildPendingSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 65,
      color: const Color(0xFF388E3C),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12),
          const Text(
            'Calendario Ganadero',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF4B5563)),
            onPressed: () {},
          ),
          Text(
            currentMonth,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF4B5563)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Vacuna', const Color(0xFF10B981)),
              _buildLegendItem('Desparasitación', const Color(0xFFF59E0B)),
              _buildLegendItem('Celo', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Palpación', const Color(0xFF8B5CF6)),
              _buildLegendItem('Parto', const Color(0xFF06B6D4)),
              _buildLegendItem('Destete', const Color(0xFF84CC16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWeekDays(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((day) => SizedBox(
        width: 45,
        child: Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final previousMonthDays = [29, 30];
    final currentMonthDays = List.generate(31, (index) => index + 1);
    final nextMonthDays = [1, 2];

    final allDays = [...previousMonthDays, ...currentMonthDays, ...nextMonthDays];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: allDays.length,
      itemBuilder: (context, index) {
        final day = allDays[index];
        final isCurrentMonth = index >= 2 && index < 33;
        final isPreviousMonth = index < 2;
        final isToday = day == 10 && isCurrentMonth;

        return _buildDayCell(
          day,
          isCurrentMonth: isCurrentMonth,
          isPreviousMonth: isPreviousMonth,
          isToday: isToday,
          events: isCurrentMonth ? dayEvents[day] : null,
        );
      },
    );
  }

  Widget _buildDayCell(
      int day, {
        required bool isCurrentMonth,
        required bool isPreviousMonth,
        required bool isToday,
        List<EventType>? events,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrentMonth
            ? (isToday ? const Color(0xFFDBEAFE) : Colors.white)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
        border: isToday ? Border.all(color: const Color(0xFF3B82F6), width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              fontSize: 12,
              color: isCurrentMonth
                  ? (isToday ? const Color(0xFF1E40AF) : const Color(0xFF111827))
                  : const Color(0xFF9CA3AF),
            ),
          ),
          if (events != null && events.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildEventIndicators(events),
          ],
        ],
      ),
    );
  }

  Widget _buildEventIndicators(List<EventType> events) {
    final displayEvents = events.take(3).toList();

    if (displayEvents.length == 1) {
      return Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: _getEventColor(displayEvents[0]),
          shape: BoxShape.circle,
        ),
      );
    } else if (displayEvents.length == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _getEventColor(displayEvents[0]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _getEventColor(displayEvents[1]),
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _getEventColor(displayEvents[0]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _getEventColor(displayEvents[1]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _getEventColor(displayEvents[2]),
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.vacuna:
        return const Color(0xFF10B981);
      case EventType.desparasitacion:
        return const Color(0xFFF59E0B);
      case EventType.celo:
        return const Color(0xFFEF4444);
      case EventType.palpacion:
        return const Color(0xFF8B5CF6);
      case EventType.parto:
        return const Color(0xFF06B6D4);
      case EventType.destete:
        return const Color(0xFF84CC16);
    }
  }

  Widget _buildPendingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendientes Hoy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildPendingItem(
            'Vacunación',
            'Lote A',
            '2 animales - 16:00 hrs',
            const Color(0xFF10B981),
            Icons.vaccines,
          ),
          const SizedBox(height: 12),
          _buildPendingItem(
            'Registrar parto',
            'Lote A',
            '2 animales',
            const Color(0xFF10B981),
            Icons.child_care,
          ),
          const SizedBox(height: 12),
          _buildPendingItem(
            'Registrar celo',
            'Lote A - 003',
            'Rutila',
            const Color(0xFF10B981),
            Icons.favorite,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItem(
      String title,
      String lote,
      String details,
      Color iconColor,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        lote,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      details,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
        ],
      ),
    );
  }
}

enum EventType {
  vacuna,
  desparasitacion,
  celo,
  palpacion,
  parto,
  destete,
}
