// lib/features/notifications/presentation/pages/reminders_page.dart
//
// Tareas (Grupo F · Tareas del rediseño).
//
// Estructura:
//   - Header: título "Tareas" + resumen dinámico + botón + con gradient.
//   - Segmented control: Hoy · Próximas · Vencidas (con contadores reales).
//   - Lista scrolleable de cards con:
//       - Checkbox circular (marca completado en el backend).
//       - Título del recordatorio.
//       - Meta: fecha relativa + tipo + vaca (si aplica).
//       - Tag de color según tipo (Vacuna azul, Celo rosa, Pesaje verde…).
//   - Banner rojo motivacional cuando hay tareas vencidas.
//
// LÓGICA CONECTADA REAL: usa ReminderService para leer / marcar como
// completado. Al abrir la pantalla se cargan TODOS los recordatorios y
// se dividen por tab en cliente.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/reminder_model.dart';
import '../../data/services/reminder_service.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

enum _Tab { hoy, proximas, vencidas }

class _RemindersPageState extends State<RemindersPage> {
  final _service = ReminderService();

  _Tab _current = _Tab.hoy;
  List<ReminderModel> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listReminders(limit: 100);
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _toggleComplete(ReminderModel r) async {
    if (r.isCompleted) return; // No permitimos "descompletar" desde aquí
    HapticFeedback.lightImpact();

    // Optimistic update
    final idx = _all.indexWhere((x) => x.id == r.id);
    if (idx == -1) return;
    setState(() {
      _all[idx] = r.copyWith(
        status: ReminderStatus.completed,
        completedAt: DateTime.now(),
      );
    });

    try {
      final updated = await _service.completeReminder(r.id);
      if (!mounted) return;
      setState(() => _all[idx] = updated);
    } catch (e) {
      if (!mounted) return;
      // Revertir
      setState(() => _all[idx] = r);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: BovaraColors.danger,
        ),
      );
    }
  }

  List<ReminderModel> get _hoy => _all
      .where((r) => r.isToday && !r.isCompleted)
      .toList()
    ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

  List<ReminderModel> get _proximas {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _all
        .where((r) => r.isPending && r.reminderDate.isAfter(today) && !r.isToday)
        .toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
  }

  List<ReminderModel> get _vencidas => _all
      .where((r) => r.isOverdue)
      .toList()
    ..sort((a, b) => b.reminderDate.compareTo(a.reminderDate));

  List<ReminderModel> get _visible {
    switch (_current) {
      case _Tab.hoy:
        return _hoy;
      case _Tab.proximas:
        return _proximas;
      case _Tab.vencidas:
        return _vencidas;
    }
  }

  String get _summary {
    final done = _hoy.where((r) => r.isCompleted).length;
    final total = _hoy.length + done;
    if (total == 0) return 'Sin tareas hoy';
    return '$done de $total completadas hoy · ${_hoy.length} pendientes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              summary: _summary,
              onBack: () => context.go('/home'),
              onAdd: _showNewReminderSheet,
            ),
            _Segmented(
              current: _current,
              hoyCount: _hoy.length,
              proxCount: _proximas.length,
              vencCount: _vencidas.length,
              onSelect: (t) => setState(() => _current = t),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: BovaraColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 42, color: BovaraColors.textMuted),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: BovaraText.body(size: 14, color: BovaraColors.textSecondary)),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _load,
                child: Text('Reintentar',
                    style: BovaraText.label(size: 13, color: BovaraColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    final items = _visible;
    if (items.isEmpty) return _EmptyState(tab: _current);

    return RefreshIndicator(
      color: BovaraColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        itemCount:
            items.length + (_current == _Tab.vencidas && items.isNotEmpty ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, i) {
          if (i == items.length) return const _VencidasBanner();
          return _TaskCard(
            reminder: items[i],
            onToggleCheck: () => _toggleComplete(items[i]),
          );
        },
      ),
    );
  }

  Future<void> _showNewReminderSheet() async {
    HapticFeedback.selectionClick();
    final created = await showModalBottomSheet<ReminderModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewReminderSheet(service: _service),
    );
    if (created != null && mounted) {
      setState(() => _all.add(created));
    }
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final String summary;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _Header({
    required this.summary,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tareas',
                    style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.23,
                    )),
                const SizedBox(height: 2),
                Text(summary,
                    style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              ],
            ),
          ),
          // Botón +
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(-0.3, -1),
                    end: Alignment(0.5, 1),
                    colors: [Color(0xFF3DA35D), BovaraColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: BovaraColors.primary.withValues(alpha: 0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SEGMENTED CONTROL
// ═════════════════════════════════════════════════════════════════

class _Segmented extends StatelessWidget {
  final _Tab current;
  final int hoyCount;
  final int proxCount;
  final int vencCount;
  final ValueChanged<_Tab> onSelect;

  const _Segmented({
    required this.current,
    required this.hoyCount,
    required this.proxCount,
    required this.vencCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6DE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(child: _Seg(label: 'Hoy · $hoyCount', selected: current == _Tab.hoy, onTap: () => onSelect(_Tab.hoy))),
            const SizedBox(width: 4),
            Expanded(child: _Seg(label: 'Próximas · $proxCount', selected: current == _Tab.proximas, onTap: () => onSelect(_Tab.proximas))),
            const SizedBox(width: 4),
            Expanded(child: _Seg(label: 'Vencidas · $vencCount', selected: current == _Tab.vencidas, onTap: () => onSelect(_Tab.vencidas))),
          ],
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Seg({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Text(
            label,
            style: BovaraText.label(
              size: 13,
              color: selected ? BovaraColors.textPrimary : BovaraColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TASK CARD
// ═════════════════════════════════════════════════════════════════

class _TaskCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onToggleCheck;

  const _TaskCard({required this.reminder, required this.onToggleCheck});

  @override
  Widget build(BuildContext context) {
    final tag = _tagFor(reminder.type);
    final isDone = reminder.isCompleted;

    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Row(
        children: [
          // Check
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleCheck,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDone ? BovaraColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? BovaraColors.primary : const Color(0xFFCED3CB),
                    width: 2.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: BovaraText.body(
                    size: 14.5,
                    color: isDone ? BovaraColors.textMuted : BovaraColors.textPrimary,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _metaFor(reminder),
                  style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: tag.bg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              tag.label,
              style: BovaraText.label(size: 10.5, color: tag.fg).copyWith(letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  String _metaFor(ReminderModel r) {
    final parts = <String>[_dateLabel(r.reminderDate)];
    if (r.description != null && r.description!.isNotEmpty) {
      parts.add(r.description!);
    }
    return parts.join(' · ');
  }

  static _TagStyle _tagFor(ReminderType t) {
    switch (t) {
      case ReminderType.vaccine:
        return _TagStyle('Vacuna', BovaraColors.infoSoftBg, BovaraColors.info);
      case ReminderType.checkup:
        return _TagStyle('Chequeo', BovaraColors.primarySoftBg, BovaraColors.primarySoftText);
      case ReminderType.treatment:
        return _TagStyle('Tratamiento', BovaraColors.warningSoftBg, const Color(0xFFA86A1E));
      case ReminderType.feeding:
        return _TagStyle('Alimento', BovaraColors.surfaceAlt, BovaraColors.textSecondary);
      case ReminderType.breeding:
        return _TagStyle('Celo', BovaraColors.celoSoftBg, BovaraColors.celoSoftText);
      case ReminderType.other:
        return _TagStyle('Otro', BovaraColors.surfaceAlt, BovaraColors.textSecondary);
    }
  }

  static String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff == -1) return 'Ayer';
    if (diff > 1 && diff < 7) return 'En $diff días';
    if (diff < -1 && diff > -7) return 'Hace ${-diff} días';

    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _TagStyle {
  final String label;
  final Color bg;
  final Color fg;
  const _TagStyle(this.label, this.bg, this.fg);
}

// ═════════════════════════════════════════════════════════════════
// BANNER DE VENCIDAS
// ═════════════════════════════════════════════════════════════════

class _VencidasBanner extends StatelessWidget {
  const _VencidasBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEBEA),
        border: Border.all(color: const Color(0xFFF2CFCB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF5D7D3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('!',
                  style: BovaraText.title(color: const Color(0xFFB03A31)).copyWith(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Las tareas vencidas afectan la salud del hato. Reprográmalas o márcalas como hechas.',
              style: BovaraText.body(size: 12.5, color: const Color(0xFF9C3A31))
                  .copyWith(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final _Tab tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (tab) {
      _Tab.hoy => (
        'Sin tareas hoy',
        'Aprovecha para planear pesajes o vacunaciones futuras.',
      ),
      _Tab.proximas => (
        'No hay próximas tareas',
        'Toca el + para programar la siguiente ronda de vacunas o revisiones.',
      ),
      _Tab.vencidas => (
        'Todo al día ✓',
        'No tienes tareas vencidas.',
      ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab == _Tab.vencidas
                  ? Icons.check_circle_outline
                  : Icons.event_available_outlined,
              size: 42,
              color: BovaraColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: BovaraText.heading()
                    .copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: BovaraText.body(size: 13, color: BovaraColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// NEW REMINDER SHEET
// ═════════════════════════════════════════════════════════════════

class _NewReminderSheet extends StatefulWidget {
  final ReminderService service;
  const _NewReminderSheet({required this.service});

  @override
  State<_NewReminderSheet> createState() => _NewReminderSheetState();
}

class _NewReminderSheetState extends State<_NewReminderSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ReminderType _type = ReminderType.checkup;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d != null) {
      setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (t != null) {
      setState(() => _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
    }
  }

  String _formatTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un título para la tarea')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final created = await widget.service.createReminder(
        title: title,
        reminderDate: _date,
        type: _type,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: BovaraColors.danger,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Text('Nueva tarea',
                    style: BovaraText.heading()
                        .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _Label('Título'),
                TextField(
                  controller: _titleCtrl,
                  autofocus: true,
                  style: BovaraText.body(size: 14),
                  cursorColor: BovaraColors.primary,
                  decoration: _inputDeco(hint: 'Ej. Vacunar Lote C'),
                ),
                const SizedBox(height: 12),
                _Label('Tipo'),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: ReminderType.values.map((t) {
                    final sel = t == _type;
                    return InkWell(
                      onTap: () => setState(() => _type = t),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? BovaraColors.darkBar : BovaraColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.display,
                          style: BovaraText.label(
                            size: 12,
                            color: sel ? Colors.white : BovaraColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Fecha'),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: BovaraColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 15, color: BovaraColors.textMuted),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(_formatFullDate(_date),
                                        overflow: TextOverflow.ellipsis,
                                        style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Hora'),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: BovaraColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 15, color: BovaraColors.textMuted),
                                  const SizedBox(width: 10),
                                  Text(_formatTime(_date),
                                      style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Label('Notas (opcional)'),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  minLines: 2,
                  style: BovaraText.body(size: 14),
                  cursorColor: BovaraColors.primary,
                  decoration: _inputDeco(hint: 'Ej. Aplicar por la mañana, verificar refrigeración'),
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(BovaraRadius.pill),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(-0.3, -1),
                          end: Alignment(0.5, 1),
                          colors: [Color(0xFF3DA35D), BovaraColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(BovaraRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: BovaraColors.primary.withValues(alpha: 0.55),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text('Guardar tarea',
                              style: BovaraText.label(size: 14.5, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle: BovaraText.body(size: 14, color: BovaraColors.textDisabled),
        filled: true,
        fillColor: BovaraColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BovaraColors.primary, width: 1.5),
        ),
      );

  String _formatFullDate(DateTime d) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text,
          style: BovaraText.label(size: 12.5, color: BovaraColors.textSecondary)),
    );
  }
}
