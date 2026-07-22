// lib/features/profile/presentation/pages/account_page.dart
//
// Mi cuenta (Grupo H · Mi cuenta del rediseño).
//
// Estructura:
//   - Header verde inmersivo con: botón atrás + avatar iniciales + nombre
//     + subtítulo "Rol · Rancho" + botón editar.
//   - Card superpuesta con 3 stats: animales / lotes / usuarios.
//   - Card blanca con 4 filas: Datos del rancho, Usuarios y roles,
//     Sincronización, Privacidad y seguridad.
//   - Card blanca con 2 filas: Ayuda y soporte, Cerrar sesión.
//   - Footer con versión + "Datos cifrados en tu dispositivo".
//
// LÓGICA CONECTADA REAL:
//   - Nombre/rol/rancho/email desde AppStateRepository (persistidos en
//     SharedPreferences por AppStateRepository).
//   - Conteo de animales real desde CattleService.getCattleList().
//   - Cerrar sesión llama a AppStateRepository.logout() (borra token +
//     perfil) y navega a /welcome.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/application/app_state_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../cattle/data/services/cattle_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _cattleService = CattleService();
  int _cattleCount = 0;
  int _loteCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final list = await _cattleService.getCattleList();
      if (!mounted) return;
      setState(() {
        _cattleCount = list.length;
        _loteCount = list.map((c) => c.lote).toSet().length;
        _loadingStats = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _confirmLogout(AppStateRepository appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BovaraColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cerrar sesión',
            style: BovaraText.heading(color: BovaraColors.textPrimary)),
        content: Text('¿Seguro que quieres salir? Tus datos se conservan.',
            style: BovaraText.body(size: 14, color: BovaraColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: BovaraText.label(size: 14, color: BovaraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Salir',
                style: BovaraText.label(size: 14, color: BovaraColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotificationService().unregisterToken();
      await appState.logout();
      if (mounted) context.go('/welcome');
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'BV';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateRepository>();
    final name = appState.displayName;
    final role = appState.userRole ?? 'Ganadero';
    final ranch = appState.ranchName ?? 'Sin rancho asignado';

    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _GreenHeader(
              name: name,
              initials: _initials(name),
              subtitle: '$role · $ranch',
              onBack: () => context.go('/home'),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -38),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsCard(
                      animales: _cattleCount,
                      lotes: _loteCount,
                      usuarios: 1, // fijo hasta que exista endpoint de miembros
                      loading: _loadingStats,
                    ),
                    const SizedBox(height: 14),
                    _MenuCard(
                      rows: [
                        _MenuRow(
                          icon: Icons.location_city_outlined,
                          bg: BovaraColors.primarySoftBg,
                          fg: BovaraColors.primary,
                          title: 'Datos del rancho',
                          subtitle: 'Nombre, ubicación, lotes',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Disponible próximamente')),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.groups_outlined,
                          bg: BovaraColors.infoSoftBg,
                          fg: BovaraColors.info,
                          title: 'Usuarios y roles',
                          subtitle: 'Capataz, veterinario, trabajadores',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Disponible próximamente')),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.sync_rounded,
                          bg: BovaraColors.primarySoftBg,
                          fg: BovaraColors.primary,
                          title: 'Sincronización',
                          subtitle: 'Última: hace 4 min · 3 pendientes',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Disponible próximamente')),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.shield_outlined,
                          bg: BovaraColors.warningSoftBg,
                          fg: const Color(0xFFB8862E),
                          title: 'Privacidad y seguridad',
                          subtitle: 'Biometría, permisos, cifrado',
                          onTap: () => context.push('/privacy'),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _MenuCard(
                      rows: [
                        _MenuRow(
                          icon: Icons.help_outline,
                          bg: BovaraColors.surfaceAlt,
                          fg: BovaraColors.textSecondary,
                          title: 'Ayuda y soporte',
                          subtitle: null,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Disponible próximamente')),
                            );
                          },
                        ),
                        _MenuRow(
                          icon: Icons.logout_rounded,
                          bg: BovaraColors.dangerSoftBg,
                          fg: BovaraColors.danger,
                          title: 'Cerrar sesión',
                          subtitle: null,
                          titleColor: BovaraColors.danger,
                          onTap: () => _confirmLogout(appState),
                          isLast: true,
                          showChevron: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Bovara v2.4.1 · Datos cifrados en tu dispositivo',
                        style: BovaraText.label(size: 11.5, color: BovaraColors.textDisabled),
                      ),
                    ),
                    const SizedBox(height: 40),
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
// GREEN HEADER
// ═════════════════════════════════════════════════════════════════

class _GreenHeader extends StatelessWidget {
  final String name;
  final String initials;
  final String subtitle;
  final VoidCallback onBack;

  const _GreenHeader({
    required this.name,
    required this.initials,
    required this.subtitle,
    required this.onBack,
  });

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
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 60),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: BovaraText.title(color: BovaraColors.primarySoftText).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: BovaraText.title(color: Colors.white).copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.19,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: BovaraText.label(
                        size: 12.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Editar perfil próximamente')),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// STATS CARD
// ═════════════════════════════════════════════════════════════════

class _StatsCard extends StatelessWidget {
  final int animales;
  final int lotes;
  final int usuarios;
  final bool loading;

  const _StatsCard({
    required this.animales,
    required this.lotes,
    required this.usuarios,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4A000000),
            blurRadius: 34,
            offset: Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCol(value: loading ? '…' : '$animales', label: 'Animales'),
            const _StatDivider(),
            _StatCol(value: loading ? '…' : '$lotes', label: 'Lotes'),
            const _StatDivider(),
            _StatCol(value: '$usuarios', label: 'Usuarios'),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: BovaraText.label(size: 11, color: BovaraColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: const Color(0xFFF0F1EB));
  }
}

// ═════════════════════════════════════════════════════════════════
// MENU CARDS
// ═════════════════════════════════════════════════════════════════

class _MenuCard extends StatelessWidget {
  final List<_MenuRow> rows;
  const _MenuCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: rows,
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool isLast;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.isLast = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF2F3ED), width: 1),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 17, color: fg),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: BovaraText.body(
                      size: 14,
                      color: titleColor ?? BovaraColors.textPrimary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right,
                  size: 18, color: BovaraColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
