// lib/features/home/presentation/pages/dashboard_page.dart
//
// Dashboard / Inicio (Grupo C del rediseño).
//
// Estructura:
//   - Saludo con nombre + avatar CP + campana con badge de notificaciones.
//   - Banner "Sincronizado hace X · Cifrado activo".
//   - Fila de KPIs: gran card verde (total ganado) + dos mini cards
//     (alertas críticas y tareas de hoy).
//   - Card "Próximas tareas" con dos items con fecha grande a la izquierda.
//   - Bottom nav de 5 tabs (Inicio · Ganado · [+] · Tareas · Asistente)
//     que expande un panel contextual arriba cuando se toca una sección.
//
// NOTAS:
//   * NO incluyo la card "Alertas de datos" (calidad de datos) porque
//     me pediste omitirla del rediseño.
//   * Los datos son reales: llaman a CattleService para el conteo total.
//     Los conteos de alertas/tareas quedan estáticos por ahora — cuando
//     rediseñemos Notifs y Tareas (Grupos F/G) los conectamos.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/application/app_state_repository.dart';
import '../../../../core/theme/theme.dart';
import '../../../cattle/data/services/cattle_service.dart';
import '../../../notifications/data/services/notification_log_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _cattleService = CattleService();
  final _notifService = NotificationLogService();
  int _cattleCount = 0;
  int _unreadCount = 0;
  bool _loadingCount = true;

  // Panel contextual del navbar. null = cerrado. valores válidos:
  //   'ganado' | 'acciones' | 'tareas' | 'asistente'
  String? _openPanel;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadUnread();
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

  Future<void> _refresh() async {
    setState(() => _loadingCount = true);
    await _loadCounts();
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
    final initials = _initialsFromName(name);

    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Contenido scrollable
            RefreshIndicator(
              onRefresh: _refresh,
              color: BovaraColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 180),
                children: [
                  _Greeting(name: name, initials: initials, unread: _unreadCount),
                  const SizedBox(height: 16),
                  const _SyncBanner(),
                  const SizedBox(height: 16),
                  _KpiRow(cattleCount: _cattleCount, loading: _loadingCount),
                  const SizedBox(height: 16),
                  const _UpcomingTasksCard(),
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
                      // Panel contextual (aparece encima del navbar)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: _openPanel == null
                            ? const SizedBox.shrink()
                            : _ContextualPanel(key: ValueKey(_openPanel), which: _openPanel!),
                      ),
                      const SizedBox(height: 10),
                      _BottomNav(
                        current: _openPanel,
                        onTapInicio: () => setState(() => _openPanel = null),
                        onTapGanado: () => _togglePanel('ganado'),
                        onTapAcciones: () => _togglePanel('acciones'),
                        onTapTareas: () => _togglePanel('tareas'),
                        onTapAsistente: () => _togglePanel('asistente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

class _Greeting extends StatelessWidget {
  final String name;
  final String initials;
  final int unread;

  const _Greeting({
    required this.name,
    required this.initials,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buen día,',
                style: BovaraText.label(
                  size: 13,
                  color: BovaraColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.23,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Campana con badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/notifications'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 22,
                    color: BovaraColors.textPrimary,
                  ),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                top: 7,
                right: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: BovaraColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        // Avatar iniciales con gradient
        GestureDetector(
          onTap: () => context.push('/account'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [BovaraColors.primary, BovaraColors.primaryDeep],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: BovaraColors.primaryDeep.withValues(alpha: 0.55),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: BovaraText.label(size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// BANNER DE SYNC
// ═════════════════════════════════════════════════════════════════

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: BovaraColors.primarySoftBg,
        border: Border.all(color: const Color(0xFFC4E2CA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: BovaraColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BovaraColors.primary.withValues(alpha: 0.18),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sincronizado hace 4 min',
            style: BovaraText.label(size: 12.5, color: BovaraColors.primarySoftText),
          ),
          const Spacer(),
          Text(
            'Cifrado activo',
            style: BovaraText.label(size: 11.5, color: const Color(0xFF5C8863)),
          ),
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
  final bool loading;

  const _KpiRow({required this.cattleCount, required this.loading});

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
                        loading
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
          // Dos mini cards apiladas
          Expanded(
            child: Column(
              children: const [
                _MiniKpiCard(
                  color: BovaraColors.danger,
                  value: '2',
                  label: 'alertas críticas',
                ),
                SizedBox(height: 12),
                _MiniKpiCard(
                  color: BovaraColors.warning,
                  value: '3',
                  label: 'tareas de hoy',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpiCard extends StatelessWidget {
  final Color color;
  final String value;
  final String label;

  const _MiniKpiCard({
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted),
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
  const _UpcomingTasksCard();

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
          _TaskRow(
            month: 'Mar',
            day: '15',
            title: 'Vacunar Lote C',
            subtitle: 'Mañana · 8:00 AM · 15 animales',
            highlight: true,
          ),
          const Divider(color: Color(0xFFF0F1EB), height: 1),
          const SizedBox(height: 13),
          _TaskRow(
            month: 'Mié',
            day: '16',
            title: 'Pesaje Lote B',
            subtitle: 'Miércoles · 9:30 AM',
            highlight: false,
          ),
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
  const _ContextualPanel({super.key, required this.which});

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
        'acciones' => const _PanelAcciones(),
        'ganado' => const _PanelGanado(),
        'tareas' => const _PanelTareas(),
        'asistente' => const _PanelAsistente(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _PanelAcciones extends StatelessWidget {
  const _PanelAcciones();

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
          children: const [
            Expanded(
              child: _QuickAction(
                icon: Icons.monitor_weight_outlined,
                label: 'Pesaje',
                bgLight: Color(0xFFF4F8F4),
                borderLight: Color(0xFFE4EFE6),
                iconBg: Color(0xFFE7F2E9),
                iconColor: BovaraColors.primary,
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: _QuickAction(
                icon: Icons.favorite_rounded,
                label: 'Celo',
                bgLight: Color(0xFFFBF0F5),
                borderLight: Color(0xFFF2DCE7),
                iconBg: Color(0xFFFCE3EE),
                iconColor: BovaraColors.celo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: const [
            Expanded(
              child: _QuickAction(
                icon: Icons.medical_services_outlined,
                label: 'Vacuna',
                bgLight: Color(0xFFEEF3FD),
                borderLight: Color(0xFFDBE6FA),
                iconBg: Color(0xFFE3ECFD),
                iconColor: BovaraColors.info,
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: _QuickAction(
                icon: Icons.child_friendly_outlined,
                label: 'Parto',
                bgLight: Color(0xFFF5F1EA),
                borderLight: Color(0xFFECE3D3),
                iconBg: Color(0xFFF1E7D4),
                iconColor: Color(0xFFB8862E),
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

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bgLight,
    required this.borderLight,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _PanelGanado extends StatelessWidget {
  const _PanelGanado();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Buscar en el hato',
            style: BovaraText.heading().copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/cattle'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: BovaraColors.textDisabled),
                const SizedBox(width: 10),
                Text('Arete, nombre o lote…',
                    style: BovaraText.body(size: 13.5, color: BovaraColors.textDisabled)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _LoteChip(label: 'Lote A · 42', active: true),
            _LoteChip(label: 'Lote B · 51'),
            _LoteChip(label: 'Lote C · 55'),
          ],
        ),
      ],
    );
  }
}

class _LoteChip extends StatelessWidget {
  final String label;
  final bool active;
  const _LoteChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: active ? BovaraColors.primary : BovaraColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: BovaraText.label(
          size: 12.5,
          color: active ? Colors.white : BovaraColors.textPrimary,
        ),
      ),
    );
  }
}

class _PanelTareas extends StatelessWidget {
  const _PanelTareas();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Pendientes de hoy · 2 de 3',
            style: BovaraText.heading().copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _PendingTaskRow(
          title: 'Pesaje matutino',
          subtitle: '7:00 AM · Lote A',
          dotColor: BovaraColors.primary,
          dotBg: const Color(0xFFE7F2E9),
        ),
        const SizedBox(height: 9),
        _PendingTaskRow(
          title: 'Control sanitario',
          subtitle: '2:00 PM · Lote C',
          dotColor: BovaraColors.info,
          dotBg: const Color(0xFFE3ECFD),
        ),
        const SizedBox(height: 12),
        // Botones de navegación a las dos vistas completas
        Row(
          children: [
            Expanded(
              child: _PanelLinkBtn(
                icon: Icons.checklist_rounded,
                label: 'Ver tareas',
                onTap: () => context.push('/reminders'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PanelLinkBtn(
                icon: Icons.calendar_month_rounded,
                label: 'Calendario',
                onTap: () => context.push('/calendar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PanelLinkBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PanelLinkBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: BovaraColors.primarySoftBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: BovaraColors.primarySoftText),
            const SizedBox(width: 7),
            Text(label,
                style: BovaraText.label(
                    size: 12.5, color: BovaraColors.primarySoftText)),
          ],
        ),
      ),
    );
  }
}

class _PendingTaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color dotColor;
  final Color dotBg;

  const _PendingTaskRow({
    required this.title,
    required this.subtitle,
    required this.dotColor,
    required this.dotBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dotBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.task_alt, size: 16, color: dotColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: BovaraText.body(size: 13.5, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: BovaraText.label(size: 12, color: BovaraColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: BovaraColors.textDisabled, size: 18),
        ],
      ),
    );
  }
}

class _PanelAsistente extends StatelessWidget {
  const _PanelAsistente();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Pregúntale a Bovi',
            style: BovaraText.heading().copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _SuggestedPrompt(text: '¿Qué vacas toca vacunar hoy?'),
        const SizedBox(height: 9),
        _SuggestedPrompt(text: '¿Alguna vaca en celo?'),
      ],
    );
  }
}

class _SuggestedPrompt extends StatelessWidget {
  final String text;
  const _SuggestedPrompt({required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/assistant'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: BovaraColors.primarySoftBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: BovaraText.body(size: 13, color: BovaraColors.primarySoftText)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
