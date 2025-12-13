// lib/features/cattle/presentation/pages/cattle_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CattleDetailPage extends StatefulWidget {
  final String cattleId;
  final Map<String, dynamic> cattleData;

  const CattleDetailPage({
    super.key,
    required this.cattleId,
    this.cattleData = const {},
  });

  @override
  State<CattleDetailPage> createState() => _CattleDetailPageState();
}

class _CattleDetailPageState extends State<CattleDetailPage> {
  int selectedTab = 0;

  List<Map<String, dynamic>> get eventHistory {
    return [
      {
        'type': 'vaccine',
        'title': 'Vacuna Triple Bovina',
        'date': '25/11/2025',
        'description': 'Aplicación de vacuna contra brucelosis',
        'icon': Icons.vaccines,
        'color': const Color(0xFF2E7D32),
        'bgColor': const Color(0xFFDCFCE7),
      },
      {
        'type': 'birth',
        'title': 'Parto registrado',
        'date': widget.cattleData['lastBirth'] ?? '12/01/2025',
        'description': 'Cría hembra, peso 35 kg',
        'icon': Icons.child_care,
        'color': const Color(0xFF7C3AED),
        'bgColor': const Color(0xFFF3E8FF),
      },
      {
        'type': 'heat',
        'title': 'Celo detectado',
        'date': '15/10/2025',
        'description': 'Duración estimada: 18-24 horas',
        'icon': Icons.favorite,
        'color': const Color(0xFFDC2626),
        'bgColor': const Color(0xFFFEE2E2),
      },
      {
        'type': 'vaccine',
        'title': 'Desparasitación',
        'date': '05/09/2025',
        'description': 'Ivermectina 1%',
        'icon': Icons.medical_services,
        'color': const Color(0xFF2E7D32),
        'bgColor': const Color(0xFFDCFCE7),
      },
    ];
  }

  void _showEventOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Agregar evento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.vaccines,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Registrar vacuna',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                subtitle: const Text(
                  'Añadir registro de vacunación',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.push('/cattle/${widget.cattleId}/vaccine');
                },
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Calcular celo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                subtitle: const Text(
                  'Estimar próximo periodo de celo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.push('/cattle/${widget.cattleId}/zeal');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.cattleData['name'] ?? 'Sin nombre';
    final lot = widget.cattleData['lot'] ?? 'Sin lote';
    final age = widget.cattleData['age'] ?? 'No especificada';
    final weight = widget.cattleData['weight'] ?? 'No registrado';
    final birthDate = widget.cattleData['birthDate'] ?? 'No especificada';
    final registrationDate = widget.cattleData['registrationDate'] ?? 'No especificada';
    final lastBirth = widget.cattleData['lastBirth'] ?? 'Sin registro';
    final nextVaccine = widget.cattleData['nextVaccine'] ?? 'Sin programar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ✅ Header CORREGIDO - Título centrado
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Botón atrás a la izquierda
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  // Título centrado
                  const Center(
                    child: Text(
                      'Vaca',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Botón menú a la derecha
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Contenido ESTÁTICO (no hace scroll)
          Expanded(
            child: Column(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Animal Info Card
                      _buildAnimalInfoCard(name, lot, age, weight),
                      const SizedBox(height: 16),
                      // Tabs
                      _buildTabs(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // ✅ Contenido del tab seleccionado
                Expanded(
                  child: selectedTab == 0
                      ? SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSummaryTab(
                          birthDate: birthDate,
                          weight: weight,
                          lastBirth: lastBirth,
                          nextVaccine: nextVaccine,
                          registrationDate: registrationDate,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                      : _buildHistoryTabWithScroll(),
                ),
              ],
            ),
          ),

          // ✅ Botón fijo abajo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showEventOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Agregar evento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalInfoCard(String name, String lot, String age, String weight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.cattleId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 92,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lote',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lot,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 92,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edad',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        age,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 68,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peso actual',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_weight_outlined,
                      size: 20,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      weight,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 0),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: selectedTab == 0
                      ? const Border(
                    bottom: BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  )
                      : null,
                ),
                child: Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedTab == 0
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 1),
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: selectedTab == 1
                      ? const Border(
                    bottom: BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  )
                      : null,
                ),
                child: Text(
                  'Historial',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedTab == 1
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab({
    required String birthDate,
    required String weight,
    required String lastBirth,
    required String nextVaccine,
    required String registrationDate,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información general',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Fecha de registro', registrationDate),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Fecha de nacimiento', birthDate),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Peso actual', weight),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Último parto', lastBirth),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildInfoRow(
            'Próxima vacuna',
            nextVaccine,
            valueColor: nextVaccine.contains('Sin')
                ? const Color(0xFF6B7280)
                : const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  // ✅ HISTORIAL CON SCROLL SOLO EN LA LISTA
  Widget _buildHistoryTabWithScroll() {
    if (eventHistory.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Sin eventos registrados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título ESTÁTICO
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Historial de eventos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
          ),
          // Lista CON SCROLL
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: eventHistory.length,
              itemBuilder: (context, index) {
                return _buildHistoryItem(eventHistory[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: event['color'],
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: event['bgColor'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              event['icon'],
              color: event['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['date'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5563),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }
}
