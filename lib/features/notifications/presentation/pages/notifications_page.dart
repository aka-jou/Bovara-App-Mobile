import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int selectedTabIndex = 0;

  final List<String> tabs = [
    'Todos',
    'Recordatorios',
    'Alertas de datos',
    'Sistema',
  ];

  final List<NotificationItem> notifications = [
    NotificationItem(
      type: NotificationType.reminder,
      title: 'Vacunar Lote A hoy a las 10:00',
      description:
      'Aplicar vacuna antiparasitaria a todos los animales del lote',
      timestamp: 'Hoy, 8:30 AM',
      isUnread: true,
      icon: Icons.event,
      color: const Color(0xFF2E7D32),
      bgColor: const Color(0xFFA5D6A7),
    ),
    NotificationItem(
      type: NotificationType.dataAlert,
      title: 'Peso fuera de rango en Vaca 03',
      description:
      'El peso registrado (850 kg) es inusualmente alto. Verifica el dato',
      timestamp: 'Hace 2 horas',
      isUnread: false,
      icon: Icons.warning,
      color: const Color(0xFFD32F2F),
      bgColor: const Color(0xFFFFCDD2),
    ),
    NotificationItem(
      type: NotificationType.reminder,
      title: 'Pesaje semanal Lote A pendiente',
      description: 'Realizar pesaje antes de las 5:00 pm',
      timestamp: 'Hoy, 7:00 AM',
      isUnread: true,
      icon: Icons.assignment,
      color: const Color(0xFF2E7D32),
      bgColor: const Color(0xFFA5D6A7),
    ),
    NotificationItem(
      type: NotificationType.alert,
      title: 'Registro incompleto en Lote C',
      description: 'Falta peso en el último pesaje de Vaca 05',
      timestamp: 'Ayer, 6:45 PM',
      isUnread: false,
      icon: Icons.error_outline,
      color: const Color(0xFFF57C00),
      bgColor: const Color(0xFFFFE0B2),
    ),
    NotificationItem(
      type: NotificationType.system,
      title: 'Sincronización completada correctamente',
      description: 'Todos los datos fueron actualizados en la nube',
      timestamp: 'Hace 30 minutos',
      isUnread: false,
      icon: Icons.cloud_done,
      color: const Color(0xFF1976D2),
      bgColor: const Color(0xFFBBDEFB),
    ),
    NotificationItem(
      type: NotificationType.reminder,
      title: 'Revisión veterinaria Lote D',
      description: 'Chequeo mensual programado para mañana 9:00 AM',
      timestamp: 'Hoy, 8:00 AM',
      isUnread: false,
      icon: Icons.edit,
      color: const Color(0xFF2E7D32),
      bgColor: const Color(0xFFA5D6A7),
    ),
    NotificationItem(
      type: NotificationType.system,
      title: 'No se pudo sincronizar con el servidor',
      description: 'Revisa tu conexión a internet e intenta de nuevo',
      timestamp: 'Hace 1 hora',
      isUnread: false,
      icon: Icons.wifi_off,
      color: const Color(0xFFD32F2F),
      bgColor: const Color(0xFFFFCDD2),
    ),
    NotificationItem(
      type: NotificationType.alert,
      title: 'Faltan registros de alimentación',
      description:
      'No hay registros de alimentación en el Lote B desde hace 3 días',
      timestamp: 'Hace 6 horas',
      isUnread: false,
      icon: Icons.storage,
      color: const Color(0xFFF57C00),
      bgColor: const Color(0xFFFFE0B2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            _buildMarkAsReadButton(),
            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 23),
                    child: _buildNotificationCard(notifications[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header / barra superior con back
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            // 👇 ahora sí regresa a la pantalla anterior
            onPressed: () {
              context.go('/home');
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
            constraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: podríamos navegar a Privacidad/Notificaciones del sistema
            },
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
            constraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filtros
  // ---------------------------------------------------------------------------
  Widget _buildFilterTabs() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            tabs.length,
                (index) => Padding(
              padding:
              EdgeInsets.only(right: index < tabs.length - 1 ? 12 : 0),
              child: _buildFilterTab(
                label: tabs[index],
                isSelected: selectedTabIndex == index,
                onTap: () => setState(() => selectedTabIndex = index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color:
          isSelected ? const Color(0xFFA5D6A7) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF616161),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Marcar todo como leído"
  // ---------------------------------------------------------------------------
  Widget _buildMarkAsReadButton() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onTap: () {
          // TODO: lógica para marcar como leído
        },
        child: const Text(
          'Marcar todo como leído',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8D6E63),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card de notificación
  // ---------------------------------------------------------------------------
  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de color
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: notification.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: notification.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        notification.icon,
                        color: notification.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // Badge + indicador de no leído
                          Row(
                            children: [
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: notification.type ==
                                      NotificationType.reminder
                                      ? const Color(0xFFF1F8E9)
                                      : notification.type ==
                                      NotificationType.dataAlert
                                      ? const Color(0xFFFFEBEE)
                                      : notification.type ==
                                      NotificationType.alert
                                      ? const Color(0xFFFFF3E0)
                                      : const Color(0xFFE3F2FD),
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                child: Text(
                                  notification.type ==
                                      NotificationType.reminder
                                      ? 'Recordatorio'
                                      : notification.type ==
                                      NotificationType.dataAlert
                                      ? 'Alerta de datos'
                                      : notification.type ==
                                      NotificationType.alert
                                      ? 'Alerta'
                                      : 'Sistema',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: notification.type ==
                                        NotificationType.reminder
                                        ? const Color(0xFF2E7D32)
                                        : notification.type ==
                                        NotificationType
                                            .dataAlert
                                        ? const Color(0xFFD32F2F)
                                        : notification.type ==
                                        NotificationType.alert
                                        ? const Color(
                                        0xFFF57C00)
                                        : const Color(
                                        0xFF1976D2),
                                  ),
                                ),
                              ),
                              if (notification.isUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Título
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF222222),
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Descripción
                          Text(
                            notification.description,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF616161),
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Timestamp
                          Text(
                            notification.timestamp,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modelos de datos
// ---------------------------------------------------------------------------

enum NotificationType {
  reminder,
  dataAlert,
  alert,
  system,
}

class NotificationItem {
  final NotificationType type;
  final String title;
  final String description;
  final String timestamp;
  final bool isUnread;
  final IconData icon;
  final Color color;
  final Color bgColor;

  NotificationItem({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isUnread,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
