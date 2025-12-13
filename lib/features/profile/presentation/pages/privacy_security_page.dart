import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool shareDataOnly = true;
  bool allowModelImprovement = false;
  bool cameraPermission = true;
  bool microphonePermission = true;
  bool notificationsPermission = true;
  SyncMode syncMode = SyncMode.wifiOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // volver a la pantalla anterior
            Navigator.of(context).pop();
            // si usas go_router puedes usar:
            // context.pop();
          },
        ),
        title: const Text(
          'Privacidad y Seguridad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            _buildPrivacySection(),
            _buildConnectivitySection(),
            _buildPermissionsSection(),
            _buildExportDataSection(),
            _buildOtherOptionsSection(),
          ],
        ),
      ),
    );
  }

  // -------------------- Secciones --------------------

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFA5D6A7).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2E7D32),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu privacidad es importante',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Controla cómo se manejan tus datos y\n'
                'configura tus preferencias de\n'
                'seguridad en Bovara.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF616161),
              height: 1.625,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRIVACIDAD Y SEGURIDAD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616161),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleOption(
            title: 'Compartir datos solo en mi\ncuenta',
            description: 'Los datos permanecen privados\nen tu cuenta.',
            value: shareDataOnly,
            onChanged: (value) => setState(() => shareDataOnly = value),
          ),
          const SizedBox(height: 24),
          _buildToggleOption(
            title: 'Permitir mejora de modelos\nlocales',
            description: 'Ayuda a mejorar el rendimiento\nlocal.',
            value: allowModelImprovement,
            onChanged: (value) =>
                setState(() => allowModelImprovement = value),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Borrar datos locales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Elimina todos los datos\nalmacenados localmente.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF616161),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: implementar borrado local
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Borrar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONECTIVIDAD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616161),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sincronización',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 16),
          _buildRadioOption(
            title: 'Solo por Wi-Fi',
            description:
            'Sincroniza únicamente cuando estés\nconectado a Wi-Fi.',
            value: SyncMode.wifiOnly,
            groupValue: syncMode,
            onChanged: (value) => setState(() => syncMode = value!),
          ),
          const SizedBox(height: 20),
          _buildRadioOption(
            title: 'Siempre',
            description:
            'Sincroniza usando Wi-Fi y datos\nmóviles.',
            value: SyncMode.always,
            groupValue: syncMode,
            onChanged: (value) => setState(() => syncMode = value!),
          ),
          const SizedBox(height: 20),
          _buildRadioOption(
            title: 'Manual',
            description: 'Sincroniza solo cuando lo solicites.',
            value: SyncMode.manual,
            groupValue: syncMode,
            onChanged: (value) => setState(() => syncMode = value!),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERMISOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616161),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionOption(
            icon: Icons.camera_alt_outlined,
            iconColor: const Color(0xFF2E7D32),
            iconBgColor: const Color(0xFFA5D6A7),
            title: 'Cámara',
            description: 'Para capturar fotos y\nvideos.',
            value: cameraPermission,
            onChanged: (value) => setState(() => cameraPermission = value),
          ),
          const SizedBox(height: 14),
          _buildPermissionOption(
            icon: Icons.mic_none,
            iconColor: const Color(0xFFF97316),
            iconBgColor: const Color(0xFFFED7AA),
            title: 'Micrófono',
            description: 'Para grabación de\naudio.',
            value: microphonePermission,
            onChanged: (value) =>
                setState(() => microphonePermission = value),
          ),
          const SizedBox(height: 14),
          _buildPermissionOption(
            icon: Icons.notifications_none,
            iconColor: const Color(0xFF3B82F6),
            iconBgColor: const Color(0xFFDBEAFE),
            title: 'Notificaciones',
            description: 'Para alertas y\nrecordatorios.',
            value: notificationsPermission,
            onChanged: (value) =>
                setState(() => notificationsPermission = value),
          ),
        ],
      ),
    );
  }

  Widget _buildExportDataSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXPORTAR DATOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616161),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildListOption(
            icon: Icons.code,
            iconColor: const Color(0xFF3B82F6),
            iconBgColor: const Color(0xFFDBEAFE),
            title: 'Exportar como JSON',
            onTap: () {
              // TODO: exportar JSON
            },
          ),
          _buildListOption(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF388E3C),
            iconBgColor: const Color(0xFFC8E6C9),
            title: 'Exportar como CSV',
            onTap: () {
              // TODO: exportar CSV
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherOptionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildListOption(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF616161),
            iconBgColor: const Color(0xFFF3F4F6),
            title: 'Política de Privacidad',
            onTap: () {},
          ),
          _buildListOption(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF616161),
            iconBgColor: const Color(0xFFF3F4F6),
            title: 'Términos de Servicio',
            onTap: () {},
          ),
          _buildListOption(
            icon: Icons.history,
            iconColor: const Color(0xFF616161),
            iconBgColor: const Color(0xFFF3F4F6),
            title: 'Ver Registros de Auditoría',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // -------------------- Helpers de UI --------------------

  Widget _buildToggleOption({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF222222),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF616161),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _CustomSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String description,
    required SyncMode value,
    required SyncMode groupValue,
    required ValueChanged<SyncMode?> onChanged,
    bool isLast = false,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFD1D5DB),
                width: isSelected ? 8 : 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF616161),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF616161),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _CustomSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildListOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF222222),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF616161),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Switch custom --------------------

class _CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF2E7D32) : const Color(0xFFD1D5DB),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedAlign(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum SyncMode {
  wifiOnly,
  always,
  manual,
}
