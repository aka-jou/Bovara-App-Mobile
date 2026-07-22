// lib/features/profile/presentation/pages/privacy_security_page.dart
//
// Privacidad y seguridad (Grupo H · Privacidad del rediseño).
//
// Estructura (tres cards agrupadas):
//   1. Acceso a la app: Face ID (toggle), Huella digital (toggle),
//      PIN de respaldo (acción "Cambiar").
//   2. Permisos por rol: lista de miembros del rancho con avatar de
//      iniciales, nombre, descripción de permisos, acción "Editar".
//   3. Tus datos: Cifrado E2E (estado activo), Descargar mis datos
//      (acción), Eliminar cuenta y datos (destructivo).
//
// NOTA: los toggles y acciones son visuales por ahora. Se dejan
// funcionales localmente para que se sienta la interacción, pero no se
// persiste el cambio ni se llama a ningún backend — hasta que exista un
// endpoint de configuración de usuario y un plugin de biometría instalado
// en el proyecto.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _faceId = true;
  bool _fingerprint = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
                children: [
                  _SectionCard(
                    label: 'Acceso a la app',
                    children: [
                      _ToggleRow(
                        icon: Icons.face_retouching_natural_outlined,
                        iconBg: BovaraColors.primarySoftBg,
                        iconFg: BovaraColors.primary,
                        title: 'Face ID',
                        subtitle: 'Desbloqueo con rostro',
                        value: _faceId,
                        onChanged: (v) => setState(() => _faceId = v),
                      ),
                      _ToggleRow(
                        icon: Icons.fingerprint_rounded,
                        iconBg: BovaraColors.primarySoftBg,
                        iconFg: BovaraColors.primary,
                        title: 'Huella digital',
                        subtitle: 'Para el capataz en campo',
                        value: _fingerprint,
                        onChanged: (v) => setState(() => _fingerprint = v),
                      ),
                      _ActionRow(
                        icon: Icons.dialpad_rounded,
                        iconBg: BovaraColors.surfaceAlt,
                        iconFg: BovaraColors.textSecondary,
                        title: 'PIN de respaldo',
                        subtitle: 'Cuando la biometría falla',
                        actionLabel: 'Cambiar',
                        onTap: () => _showComingSoon(),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    label: 'Permisos por rol',
                    children: const [
                      _MemberRow(
                        initials: 'JM',
                        initialsBg: BovaraColors.primarySoftBg,
                        initialsFg: BovaraColors.primarySoftText,
                        name: 'Juan Martínez · Capataz',
                        permissions: 'Registrar y editar eventos',
                      ),
                      _MemberRow(
                        initials: 'DR',
                        initialsBg: BovaraColors.infoSoftBg,
                        initialsFg: BovaraColors.info,
                        name: 'Dra. Ríos · Veterinaria',
                        permissions: 'Historial clínico completo',
                      ),
                      _MemberRow(
                        initials: 'PL',
                        initialsBg: BovaraColors.warningSoftBg,
                        initialsFg: Color(0xFFB8862E),
                        name: 'Pedro López · Trabajador',
                        permissions: 'Solo registrar, sin editar',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    label: 'Tus datos',
                    children: [
                      _StaticRow(
                        icon: Icons.check_circle_outlined,
                        iconBg: BovaraColors.primarySoftBg,
                        iconFg: BovaraColors.primary,
                        title: 'Cifrado de extremo a extremo',
                        subtitle: 'Activo · AES-256',
                        subtitleColor: BovaraColors.primarySoftText,
                      ),
                      _ActionRow(
                        icon: Icons.download_rounded,
                        iconBg: BovaraColors.infoSoftBg,
                        iconFg: BovaraColors.info,
                        title: 'Descargar mis datos',
                        subtitle: 'Exportar todo en CSV',
                        onTap: () => _showComingSoon(),
                      ),
                      _ActionRow(
                        icon: Icons.delete_outline_rounded,
                        iconBg: BovaraColors.dangerSoftBg,
                        iconFg: BovaraColors.danger,
                        title: 'Eliminar cuenta y datos',
                        subtitle: 'Irreversible tras 30 días',
                        titleColor: BovaraColors.danger,
                        onTap: () => _showDeleteConfirm(),
                        isLast: true,
                        showChevron: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disponible próximamente')),
    );
  }

  Future<void> _showDeleteConfirm() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BovaraColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar cuenta',
            style: BovaraText.heading(color: BovaraColors.danger)),
        content: Text(
          'Esta acción es irreversible tras 30 días. Se eliminarán tus animales, eventos y recordatorios. ¿Continuar?',
          style: BovaraText.body(size: 14, color: BovaraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: BovaraText.label(size: 14, color: BovaraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showComingSoon();
            },
            child: Text('Eliminar',
                style: BovaraText.label(size: 14, color: BovaraColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
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
                Text('Privacidad y seguridad',
                    style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.19,
                    )),
                const SizedBox(height: 1),
                Text('Tu rancho, tus reglas',
                    style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SECTION CARD (wrapper con label pequeña)
// ═════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SectionCard({required this.label, required this.children});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 14, 17, 6),
            child: Text(
              label.toUpperCase(),
              style: BovaraText.label(size: 11, color: BovaraColors.textMuted)
                  .copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w800),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ROWS
// ═════════════════════════════════════════════════════════════════

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 17, color: iconFg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: BovaraColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool isLast;
  final bool showChevron;

  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.actionLabel,
    this.titleColor,
    this.isLast = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF6F7F2), width: 1),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 17, color: iconFg),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: BovaraText.body(
                        size: 14,
                        color: titleColor ?? BovaraColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted)),
                ],
              ),
            ),
            if (actionLabel != null)
              Text(actionLabel!,
                  style: BovaraText.label(size: 12, color: BovaraColors.primary))
            else if (showChevron)
              const Icon(Icons.chevron_right, size: 18, color: BovaraColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final Color? subtitleColor;

  const _StaticRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF6F7F2), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 17, color: iconFg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: BovaraText.label(
                      size: 11.5,
                      color: subtitleColor ?? BovaraColors.textMuted,
                    ).copyWith(fontWeight: subtitleColor != null ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String initials;
  final Color initialsBg;
  final Color initialsFg;
  final String name;
  final String permissions;
  final bool isLast;

  const _MemberRow({
    required this.initials,
    required this.initialsBg,
    required this.initialsFg,
    required this.name,
    required this.permissions,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF6F7F2), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: initialsBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initials,
                style: BovaraText.label(size: 13, color: initialsFg)
                    .copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(permissions,
                    style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted)),
              ],
            ),
          ),
          Text('Editar',
              style: BovaraText.label(size: 12, color: BovaraColors.primary)),
        ],
      ),
    );
  }
}
