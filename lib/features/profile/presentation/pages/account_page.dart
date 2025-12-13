// lib/src/features/auth/presentation/pages/account_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/application/app_state_repository.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _notificationsEnabled = true;

  String _initialsFromEmailOrName(String? value) {
    if (value == null || value.trim().isEmpty) return 'BV';
    final trimmed = value.trim();

    // si parece correo, usamos la primera letra
    if (trimmed.contains('@')) {
      return trimmed[0].toUpperCase();
    }

    // si parece nombre, tomamos primeras letras
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'BV';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateRepository>();

    // demo: en el futuro estos vendrán del backend / perfil del usuario
    final nombre = appState.userName ?? 'Don Carlos Pérez';
    final rol = appState.userRole ?? 'Ganadero / Propietario';
    final rancho = appState.ranchName ?? 'La Esperanza';
    final telefono = appState.userPhone ?? '+52 961 123 4567';
    final email = appState.userEmail ?? 'don.carlos@ejemplo.com';

    final initials = _initialsFromEmailOrName(nombre.isNotEmpty ? nombre : email);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Mi cuenta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Card de perfil
            _ProfileHeaderCard(
              initials: initials,
              name: nombre,
              role: rol,
            ),
            const SizedBox(height: 16),

            // Card de datos de la cuenta
            _AccountDataCard(
              phone: telefono,
              email: email,
              role: rol,
              ranch: rancho,
            ),
            const SizedBox(height: 16),

            // Card de ajustes
            _SettingsCard(
              notificationsEnabled: _notificationsEnabled,
              onNotificationsChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Botón cerrar sesión
            _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

/// Card superior con avatar + nombre + rol
class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String name;
  final String role;

  const _ProfileHeaderCard({
    required this.initials,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF2E7D32),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF222222),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF616161),
                      fontSize: 16,
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

/// Card con datos de teléfono, correo, rol y rancho
class _AccountDataCard extends StatelessWidget {
  final String phone;
  final String email;
  final String role;
  final String ranch;

  const _AccountDataCard({
    required this.phone,
    required this.email,
    required this.role,
    required this.ranch,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: const Text(
              'Datos de la cuenta',
              style: TextStyle(
                color: Color(0xFF222222),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Teléfono
          _AccountDataRow(
            icon: Icons.phone_iphone_outlined,
            label: 'Teléfono',
            value: phone,
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // Correo
          _AccountDataRow(
            icon: Icons.mail_outline,
            label: 'Correo electrónico',
            value: email,
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // Rol
          _AccountDataRow(
            icon: Icons.badge_outlined,
            label: 'Rol en el rancho',
            value: role,
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // Rancho
          _AccountDataRow(
            icon: Icons.agriculture_outlined,
            label: 'Rancho',
            value: ranch,
          ),
        ],
      ),
    );
  }
}

class _AccountDataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountDataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x4CA5D6A7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF616161),
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF222222),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

/// Card con ajustes
class _SettingsCard extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  const _SettingsCard({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: const Text(
              'Ajustes',
              style: TextStyle(
                color: Color(0xFF222222),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: _settingsIcon(Icons.edit_outlined),
            title: const Text(
              'Editar datos de la cuenta',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF222222),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () {
              // TODO: navegar a editar perfil
            },
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            leading: _settingsIcon(Icons.lock_reset_outlined),
            title: const Text(
              'Cambiar contraseña',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF222222),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () {
              // TODO: navegar a cambiar contraseña
            },
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            leading: _settingsIcon(Icons.notifications_active_outlined),
            title: const Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF222222),
              ),
            ),
            trailing: Switch(
              value: notificationsEnabled,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF2E7D32),
              onChanged: onNotificationsChanged,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            leading: _settingsIcon(Icons.shield_outlined),
            title: const Text(
              'Privacidad y seguridad',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF222222),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () {
              context.push('/privacy');
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0x4CA5D6A7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
    );
  }
}

/// Botón rojo de cerrar sesión
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        onPressed: () {
          // logout global
          context.read<AppStateRepository>().setLoggedIn(false);

          // llevar al welcome (o login)
          context.go('/welcome');
        },
      ),
    );
  }
}
