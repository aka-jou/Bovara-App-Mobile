// lib/features/home/presentation/pages/dashboard_page.dart
//
// Dashboard / Inicio (Grupo C del rediseño).
//
// Estructura:
//   - Saludo con nombre + avatar CP + campana con badge de notificaciones.
//   - Banner "Sincronizado hace X · Cifrado activo".
//   - Fila de KPIs: gran card verde (total ganado) + card "tareas de hoy",
//     ambas del mismo tamaño.
//   - Card "Próximas tareas" con los recordatorios pendientes reales del
//     usuario (fecha grande a la izquierda).
//   - Bottom nav de 5 tabs (Inicio · Ganado · [+] · Tareas · Asistente)
//     que expande un panel contextual arriba cuando se toca una sección.
//
// NOTAS:
//   * NO incluyo la card "Alertas de datos" (calidad de datos) porque
//     me pediste omitirla del rediseño.
//   * Se quitó la card "alertas críticas" (era un valor fijo de ejemplo).
//   * Todo es real: cabezas en total, tareas de hoy y próximas tareas
//     vienen de CattleService / ReminderService.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/application/app_state_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../cattle/data/models/cattle_model.dart';
import '../../../cattle/data/services/cattle_service.dart';
import '../../../notifications/data/services/notification_log_service.dart';
import '../../../notifications/data/services/reminder_service.dart';
import '../../../notifications/data/models/reminder_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _cattleService = CattleService();
  final _notifService = NotificationLogService();
  final _reminderService = ReminderService();
  int _cattleCount = 0;
  int _unreadCount = 0;
  int _todayCount = 0;
  List<ReminderModel> _upcomingReminders = [];
  bool _loadingCount = true;
  bool _loadingTasks = true;

  // Panel contextual del navbar. null = cerrado. valores válidos:
  //   'ganado' | 'acciones' | 'tareas' | 'asistente'
  String? _openPanel;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadUnread();
    _loadTasks();
  }

  Future<void> _loadUnread() async {
    try {
      final list = await _notifService.list();
      if (mounted) setState(() => _unreadCount = list.where((n) => !n.isRead).length);
    } catch (_) {
      // Silencioso: el badge simplemente no se actualiza si falla.
    }
  }

  Future<void> _loadCounts() async {
    try {
      final list = await _cattleService.getCattleList();
      if (mounted) {
        setState(() {
          _cattleCount = list.length;
          _loadingCount = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCount = false);
    }
  }

  /// Carga los recordatorios pendientes reales del usuario: cuenta los de
  /// hoy para la mini card, y toma los 2 más próximos para la card de
  /// "Próximas tareas" (ordenados por fecha, sin importar si ya vencieron).
  Future<void> _loadTasks() async {
    try {
      final pending = await _reminderService.listReminders(
        status: ReminderStatus.pending,
        limit: 100,
      );
      pending.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
      if (mounted) {
        setState(() {
          _todayCount = pending.where((r) => r.isToday).length;
          _upcomingReminders = pending.take(2).toList();
          _loadingTasks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTasks = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadingCount = true;
      _loadingTasks = true;
    });
    await Future.wait([_loadCounts(), _loadTasks()]);
  }

  /// Muestra una lista de vacas para elegir a cuál aplicarle una acción
  /// (celo, evento), y navega a esa ruta ya con el animal seleccionado.
  /// Sin esto, /cattle/:id/zeal y /cattle/:id/vaccine no sabrían de
  /// cuál vaca se trata.
  Future<void> _pickCattleAndNavigate(String routeSuffix, String title) async {
    setState(() => _openPanel = null);
    List<CattleModel> list;
    try {
      list = await _cattleService.getCattleList();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pude cargar tu hato. Intenta de nuevo.')),
      );
      return;
    }
    if (!mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todavía no tienes animales registrados.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<CattleModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: BovaraText.heading().copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('¿A qué animal?',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F1EB)),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name, style: BovaraText.body(size: 14).copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text('Lote: ${c.lote}', style: BovaraText.label(size: 12, color: BovaraColors.textMuted)),
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    context.push('/cattle/${selected.id}/$routeSuffix', extra: selected);
  }

  /// Para "Celo": primero elige el LOTE (el corral), y ya dentro de ese
  /// lote elige la vaca especifica. Pensado para ranchos donde varias
  /// vacas comparten lote — mas natural que buscar directo en la lista
  /// completa del hato.
  Future<void> _pickLoteThenCattleForZeal() async {
    setState(() => _openPanel = null);
    List<CattleModel> all;
    try {
      all = await _cattleService.getCattleList();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pude cargar tu hato. Intenta de nuevo.')),
      );
      return;
    }
    if (!mounted) return;
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todavía no tienes animales registrados.')),
      );
      return;
    }

    final lotes = <String, List<CattleModel>>{};
    for (final c in all) {
      lotes.putIfAbsent(c.lote, () => []).add(c);
    }
    final loteKeys = lotes.keys.toList()..sort();

    final selectedLote = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar celo',
                  style: BovaraText.heading().copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('¿En qué lote (corral)?',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: loteKeys.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F1EB)),
                  itemBuilder: (_, i) {
                    final lote = loteKeys[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Lote $lote', style: BovaraText.body(size: 14).copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${lotes[lote]!.length} ${lotes[lote]!.length == 1 ? 'animal' : 'animales'}',
                        style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                      ),
                      onTap: () => Navigator.pop(ctx, lote),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedLote == null || !mounted) return;
    final cattleInLote = lotes[selectedLote]!;

    CattleModel? selectedCattle;
    if (cattleInLote.length == 1) {
      selectedCattle = cattleInLote.first;
    } else {
      selectedCattle = await showModalBottomSheet<CattleModel>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lote $selectedLote',
                    style: BovaraText.heading().copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('¿Qué vaca de este lote?',
                    style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cattleInLote.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F1EB)),
                    itemBuilder: (_, i) {
                      final c = cattleInLote[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.name, style: BovaraText.body(size: 14).copyWith(fontWeight: FontWeight.w700)),
                        onTap: () => Navigator.pop(ctx, c),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (selectedCattle == null || !mounted) return;
    context.push('/cattle/${selectedCattle.id}/zeal', extra: selectedCattle);
  }

  void _togglePanel(String key) {
    setState(() {
      _openPanel = _openPanel == key ? null : key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateRepository>();
    final name = appState.displayName;

    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      extendBody: true,
      body: Column(
        children: [
          _DashboardGreenHeader(
            name: name,
            unread: _unreadCount,
            onBell: () => context.push('/notifications'),
          ),
          Expanded(
            child: Stack(
              children: [
                // Contenido scrollable
                RefreshIndicator(
                  onRefresh: _refresh,
                  color: BovaraColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 180),
                    children: [
                      _KpiRow(
                        cattleCount: _cattleCount,
                        loadingCattle: _loadingCount,
                        todayCount: _todayCount,
                        loadingTasks: _loadingTasks,
                      ),
                      const SizedBox(height: 16),
                      _UpcomingTasksCard(
                        reminders: _upcomingReminders,
                        loading: _loadingTasks,
                      ),
                      const SizedBox(height: 16),
                      const _DashboardCalendarCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
            // Navbar + panel expandible
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Panel contextual (aparece encima del navbar) —
                      // ahora SOLO existe para el botón [+] ("acciones").
                      // Ganado/Tareas/Asistente ya no despliegan panel:
                      // navegan directo a su vista.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: _openPanel == null
                            ? const SizedBox.shrink()
                            : _ContextualPanel(
                                key: ValueKey(_openPanel),
                                which: _openPanel!,
                                onPickCattleFor: _pickCattleAndNavigate,
                                onCeloTap: _pickLoteThenCattleForZeal,
                              ),
                      ),
                      const SizedBox(height: 10),
                      _BottomNav(
                        current: _openPanel,
                        onTapInicio: () => setState(() => _openPanel = null),
                        onTapGanado: () {
                          setState(() => _openPanel = null);
                          context.push('/cattle');
                        },
                        onTapAcciones: () => _togglePanel('acciones'),
                        onTapTareas: () {
                          setState(() => _openPanel = null);
                          context.push('/reminders');
                        },
                        onTapAsistente: () {
                          setState(() => _openPanel = null);
                          context.push('/assistant');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════
// SALUDO + AVATAR + CAMPANA
// ═════════════════════════════════════════════════════════════════

class _DashboardGreenHeader extends StatelessWidget {
  final String name;
  final int unread;
  final VoidCallback onBell;

  const _DashboardGreenHeader({
    required this.name,
    required this.unread,
    required this.onBell,
  });

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'BV';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BovaraColors.primary, Color(0xFF1B5C2C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => context.push('/account'),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(name),
                style: BovaraText.title(color: BovaraColors.primarySoftText).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buen día,',
                  style: BovaraText.label(size: 12.5, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  style: BovaraText.title(color: Colors.white).copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBell,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    child: const Icon(Icons.notifications_none_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: 5,
                  right: 4,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: BovaraColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: BovaraColors.primary, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CALENDARIO DEL DASHBOARD (real: marca dias con recordatorios)
// ═════════════════════════════════════════════════════════════════

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 8),
            spreadRadius: -14,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DashboardCalendarCard extends StatefulWidget {
  const _DashboardCalendarCard();

  @override
  State<_DashboardCalendarCard> createState() => _DashboardCalendarCardState();
}

class _DashboardCalendarCardState extends State<_DashboardCalendarCard> {
  final _reminderService = ReminderService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  bool _loading = true;
  Map<int, List<ReminderModel>> _byDay = {}; // dia del mes -> recordatorios

  static const _weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _monthNames = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(_month.year, _month.month, 1);
      final end = DateTime(_month.year, _month.month + 1, 0);
      final reminders = await _reminderService.listReminders(
        startDate: start,
        endDate: end,
        limit: 200,
      );
      final map = <int, List<ReminderModel>>{};
      for (final r in reminders) {
        if (r.reminderDate.year == _month.year && r.reminderDate.month == _month.month) {
          map.putIfAbsent(r.reminderDate.day, () => []).add(r);
        }
      }
      if (!mounted) return;
      setState(() {
        _byDay = map;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Lunes=1 ... Domingo=7 -> celdas vacias antes del dia 1
    final leadingBlanks = firstOfMonth.weekday - 1;
    final today = DateTime.now();

    final selectedReminders = _byDay[_selectedDay.day] ?? [];
    final selectedIsInMonth =
        _selectedDay.year == _month.year && _selectedDay.month == _month.month;

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Calendario',
                    style: BovaraText.heading().copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, size: 20, color: BovaraColors.textMuted),
                visualDensity: VisualDensity.compact,
              ),
              Text('${_monthNames[_month.month]} ${_month.year}',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textSecondary)),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, size: 20, color: BovaraColors.textMuted),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: BovaraColors.primary, strokeWidth: 2.4),
              ),
            )
          else ...[
            Row(
              children: [
                for (final w in _weekdayLabels)
                  Expanded(
                    child: Center(
                      child: Text(w,
                          style: BovaraText.label(size: 11, color: BovaraColors.textDisabled)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (_, i) {
                if (i < leadingBlanks) return const SizedBox.shrink();
                final day = i - leadingBlanks + 1;
                final date = DateTime(_month.year, _month.month, day);
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected = selectedIsInMonth && day == _selectedDay.day;
                final hasReminders = _byDay.containsKey(day);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? BovaraColors.primary
                          : (isToday ? BovaraColors.primarySoftBg : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day',
                            style: BovaraText.label(
                              size: 12,
                              color: isSelected ? Colors.white : BovaraColors.textPrimary,
                            )),
                        if (hasReminders)
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : BovaraColors.celo,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFF0F1EB), height: 1),
            const SizedBox(height: 10),
            if (!selectedIsInMonth || selectedReminders.isEmpty)
              Text('Sin recordatorios ese día.',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted))
            else
              for (final r in selectedReminders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: BovaraColors.celo, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.title,
                            style: BovaraText.body(size: 13, color: BovaraColors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        '${r.reminderDate.hour.toString().padLeft(2, '0')}:${r.reminderDate.minute.toString().padLeft(2, '0')}',
                        style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FILA DE KPIs
// ═════════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  final int cattleCount;
  final bool loadingCattle;
  final int todayCount;
  final bool loadingTasks;

  const _KpiRow({
    required this.cattleCount,
    required this.loadingCattle,
    required this.todayCount,
    required this.loadingTasks,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Card grande verde (total ganado)
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/cattle'),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(-0.3, -1),
                    end: Alignment(0.7, 1),
                    colors: [BovaraColors.primary, Color(0xFF1B5C2C)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: BovaraColors.primaryDeep.withValues(alpha: 0.55),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                      spreadRadius: -18,
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      right: -14,
                      top: -14,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        loadingCattle
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                '$cattleCount',
                                style: BovaraText.title(color: Colors.white).copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                        const SizedBox(height: 4),
                        Text(
                          'cabezas en total',
                          style: BovaraText.label(
                            size: 12.5,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Card "tareas de hoy", mismo tamaño que la card verde.
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/reminders'),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                      spreadRadius: -14,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: BovaraColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    loadingTasks
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: BovaraColors.warning,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            '$todayCount',
                            style: BovaraText.title(color: BovaraColors.textPrimary)
                                .copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -0.5,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      'tareas de hoy',
                      style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CARD DE PRÓXIMAS TAREAS
// ═════════════════════════════════════════════════════════════════

class _UpcomingTasksCard extends StatelessWidget {
  final List<ReminderModel> reminders;
  final bool loading;

  const _UpcomingTasksCard({required this.reminders, required this.loading});

  static const _months = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  static const _weekdays = [
    '', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  String _relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 0) return 'Venció el ${_weekdays[d.weekday]}';
    return _weekdays[d.weekday];
  }

  String _time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Próximas tareas',
                  style: BovaraText.heading().copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/reminders'),
                child: Text(
                  'Ver todas',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: BovaraColors.primary,
                    strokeWidth: 2.4,
                  ),
                ),
              ),
            )
          else if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No tienes tareas pendientes por ahora.',
                style: BovaraText.label(size: 13, color: BovaraColors.textMuted),
              ),
            )
          else
            for (int i = 0; i < reminders.length; i++) ...[
              if (i > 0) ...[
                const Divider(color: Color(0xFFF0F1EB), height: 1),
                const SizedBox(height: 13),
              ],
              _TaskRow(
                month: _months[reminders[i].reminderDate.month],
                day: '${reminders[i].reminderDate.day}',
                title: reminders[i].title,
                subtitle:
                    '${_relativeDay(reminders[i].reminderDate)} · ${_time(reminders[i].reminderDate)}',
                highlight: reminders[i].isToday || reminders[i].isOverdue,
              ),
            ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String subtitle;
  final bool highlight;

  const _TaskRow({
    required this.month,
    required this.day,
    required this.title,
    required this.subtitle,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          // Bloque de fecha grande
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: highlight ? const Color(0xFFE7F2E9) : const Color(0xFFF1F1F4),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: BovaraText.label(
                    size: 10,
                    color: highlight ? BovaraColors.primary : BovaraColors.textMuted,
                  ).copyWith(letterSpacing: 0.8),
                ),
                Text(
                  day,
                  style: BovaraText.title(
                    color: highlight ? BovaraColors.primarySoftText : BovaraColors.textPrimary,
                  ).copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BovaraText.body(size: 14.5, color: BovaraColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// BOTTOM NAV
// ═════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final String? current;
  final VoidCallback onTapInicio;
  final VoidCallback onTapGanado;
  final VoidCallback onTapAcciones;
  final VoidCallback onTapTareas;
  final VoidCallback onTapAsistente;

  const _BottomNav({
    required this.current,
    required this.onTapInicio,
    required this.onTapGanado,
    required this.onTapAcciones,
    required this.onTapTareas,
    required this.onTapAsistente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BovaraColors.darkBar,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C0B0D0B),
            blurRadius: 40,
            offset: Offset(0, 18),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Inicio',
            selected: current == null,
            onTap: onTapInicio,
          ),
          _NavItem(
            icon: Icons.pets_rounded,
            label: 'Ganado',
            selected: current == 'ganado',
            onTap: onTapGanado,
          ),
          _NavCenterButton(onTap: onTapAcciones, active: current == 'acciones'),
          _NavItem(
            icon: Icons.checklist_rounded,
            label: 'Tareas',
            selected: current == 'tareas',
            onTap: onTapTareas,
          ),
          _NavItem(
            icon: Icons.smart_toy_rounded,
            label: 'Asistente',
            selected: current == 'asistente',
            onTap: onTapAsistente,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? BovaraColors.primary : BovaraColors.textOnDarkMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: BovaraText.label(
                size: 10,
                color: selected ? BovaraColors.primary : BovaraColors.textOnDarkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCenterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool active;

  const _NavCenterButton({required this.onTap, required this.active});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 240),
        turns: active ? 0.125 : 0, // +45deg cuando está activo → forma de X
        child: Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.3, -1),
              end: Alignment(0.5, 1),
              colors: [Color(0xFF3DA35D), BovaraColors.primary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: BovaraColors.primary.withValues(alpha: 0.8),
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -8,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PANEL CONTEXTUAL (aparece encima del navbar cuando toca una sección)
// ═════════════════════════════════════════════════════════════════

class _ContextualPanel extends StatelessWidget {
  final String which;
  final Future<void> Function(String routeSuffix, String title) onPickCattleFor;
  final Future<void> Function() onCeloTap;
  const _ContextualPanel({super.key, required this.which, required this.onPickCattleFor, required this.onCeloTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 30,
            offset: Offset(0, -6),
            spreadRadius: -12,
          ),
        ],
      ),
      child: switch (which) {
        'acciones' => _PanelAcciones(onPickCattleFor: onPickCattleFor, onCeloTap: onCeloTap),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _PanelAcciones extends StatelessWidget {
  final Future<void> Function(String routeSuffix, String title) onPickCattleFor;
  final Future<void> Function() onCeloTap;
  const _PanelAcciones({required this.onPickCattleFor, required this.onCeloTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Registro rápido',
            style: BovaraText.heading().copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.add_circle_outline,
                label: 'Crear vaca',
                bgLight: const Color(0xFFF4F8F4),
                borderLight: const Color(0xFFE4EFE6),
                iconBg: const Color(0xFFE7F2E9),
                iconColor: BovaraColors.primary,
                onTap: () => context.push('/cattle/new'),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _QuickAction(
                icon: Icons.favorite_rounded,
                label: 'Celo',
                bgLight: const Color(0xFFFBF0F5),
                borderLight: const Color(0xFFF2DCE7),
                iconBg: const Color(0xFFFCE3EE),
                iconColor: BovaraColors.celo,
                onTap: () => onCeloTap(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.smart_toy_outlined,
                label: 'Hablar con Bovi',
                bgLight: const Color(0xFFEEF3FD),
                borderLight: const Color(0xFFDBE6FA),
                iconBg: const Color(0xFFE3ECFD),
                iconColor: BovaraColors.info,
                onTap: () => context.push('/assistant', extra: 'Hola Bovi'),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: _QuickAction(
                icon: Icons.event_note_outlined,
                label: 'Crear evento',
                bgLight: const Color(0xFFF5F1EA),
                borderLight: const Color(0xFFECE3D3),
                iconBg: const Color(0xFFF1E7D4),
                iconColor: const Color(0xFFB8862E),
                onTap: () => onPickCattleFor('vaccine', 'Crear evento'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgLight;
  final Color borderLight;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bgLight,
    required this.borderLight,
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: bgLight,
            border: Border.all(color: borderLight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: BovaraText.body(size: 13.5, color: BovaraColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
