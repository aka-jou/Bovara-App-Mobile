// lib/features/cattle/presentation/pages/cattle_detail_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/cattle_model.dart';
import '../../data/models/health_event_model.dart';
import '../../data/models/heat_event_model.dart';
import '../../data/services/cattle_service.dart';
import '../../data/services/health_event_service.dart';
import '../../data/services/heat_event_service.dart';

class CattleDetailPage extends StatefulWidget {
  final String cattleId;
  final CattleModel? cattle; // Recibido desde lista

  const CattleDetailPage({
    super.key,
    required this.cattleId,
    this.cattle,
  });

  @override
  State<CattleDetailPage> createState() => _CattleDetailPageState();
}

class _CattleDetailPageState extends State<CattleDetailPage> {
  final CattleService _cattleService = CattleService();
  final HealthEventService _healthService = HealthEventService();
  final HeatEventService _heatService = HeatEventService();

  int selectedTab = 0;
  bool isLoading = true;
  String? errorMessage;

  CattleModel? cattle;
  List<HealthEventModel> healthEvents = [];
  List<HeatEventModel> heatEvents = [];

  DateTime? lastHeatDate;
  String clusterLabel = 'Sin clasificar';

  @override
  void initState() {
    super.initState();
    cattle = widget.cattle;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 🔄 Cargar datos de la vaca (si no vino de lista)
      if (cattle == null) {
        cattle = await _cattleService.getCattleById(widget.cattleId);
      }

      // 🔄 Cargar eventos de salud
      healthEvents = await _healthService.getHealthEventsByCattle(widget.cattleId);

      // 🔄 Cargar eventos de celo
      heatEvents = await _heatService.getHeatEventsByCattle(widget.cattleId);

      // 📊 Calcular último celo
      if (heatEvents.isNotEmpty) {
        heatEvents.sort((a, b) => b.heatDate.compareTo(a.heatDate));
        lastHeatDate = heatEvents.first.heatDate;
      }

      // 🧬 Calcular cluster de salud
      _calculateHealthCluster();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _calculateHealthCluster() {
    if (cattle == null) return;

    final eventos = healthEvents.length + heatEvents.length;
    final vacunas = healthEvents.where((e) => e.eventType == 'vaccine').length;
    final tratamientos = healthEvents.where((e) => e.eventType == 'treatment').length;
    final enfermedades = healthEvents.where((e) => e.eventType == 'illness').length;

    setState(() {
      clusterLabel = cattle!.getHealthCluster(eventos, vacunas, tratamientos, enfermedades);
    });
  }

  // 🆕 Construir lista combinada de eventos (salud + celo)
  List<Map<String, dynamic>> get combinedEvents {
    List<Map<String, dynamic>> events = [];

    // Agregar eventos de salud
    for (var event in healthEvents) {
      events.add({
        'type': event.eventType,
        'title': event.eventTypeSpanish,
        'date': event.formattedDate,
        'description': event.medicineName ?? event.diseaseName ?? 'Sin detalles',
        'icon': _getHealthIcon(event.eventType),
        'color': _getHealthColor(event.eventType),
        'bgColor': _getHealthBgColor(event.eventType),
        'originalDate': event.applicationDate,
      });
    }

    // Agregar eventos de celo
    for (var event in heatEvents) {
      events.add({
        'type': 'heat',
        'title': 'Celo detectado',
        'date': event.formattedHeatDate,
        'description': event.wasInseminated
            ? 'Inseminada el ${event.formattedInseminationDate}'
            : 'Sin inseminar',
        'icon': Icons.favorite,
        'color': const Color(0xFFDC2626),
        'bgColor': const Color(0xFFFEE2E2),
        'originalDate': event.heatDate,
      });
    }

    // Ordenar por fecha descendente
    events.sort((a, b) => (b['originalDate'] as DateTime).compareTo(a['originalDate'] as DateTime));

    return events;
  }

  IconData _getHealthIcon(String type) {
    switch (type) {
      case 'vaccine':
        return Icons.vaccines;
      case 'treatment':
        return Icons.medical_services;
      case 'checkup':
        return Icons.monitor_heart;
      case 'surgery':
        return Icons.local_hospital;
      case 'illness':
        return Icons.sick;
      default:
        return Icons.event_note;
    }
  }

  Color _getHealthColor(String type) {
    switch (type) {
      case 'vaccine':
        return const Color(0xFF2E7D32);
      case 'treatment':
        return const Color(0xFFD97706);
      case 'illness':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getHealthBgColor(String type) {
    switch (type) {
      case 'vaccine':
        return const Color(0xFFDCFCE7);
      case 'treatment':
        return const Color(0xFFFEF3C7);
      case 'illness':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
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
                  'Registrar vacuna/tratamiento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                subtitle: const Text(
                  'Añadir registro de salud',
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
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Registrar celo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                subtitle: const Text(
                  'Detectar periodo de celo',
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
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF388E3C),
          title: const Text('Cargando...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (errorMessage != null || cattle == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF388E3C),
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFDC2626)),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar los datos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage ?? 'Datos no disponibles',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Detalles de Vaca',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                      onPressed: _loadData,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: Column(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildAnimalInfoCard(),
                      const SizedBox(height: 16),
                      _buildTabs(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                Expanded(
                  child: selectedTab == 0
                      ? SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSummaryTab(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                      : _buildHistoryTabWithScroll(),
                ),
              ],
            ),
          ),

          // Botón fijo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildAnimalInfoCard() {
    final nextHeatDays = cattle!.daysUntilNextHeat(lastHeatDate);
    final nextHeatText = cattle!.formattedNextHeat(lastHeatDate);

    // Color del badge de próximo celo
    Color nextHeatColor = const Color(0xFF6B7280);
    Color nextHeatBgColor = const Color(0xFFF3F4F6);

    if (nextHeatDays != null) {
      if (nextHeatDays <= 0) {
        nextHeatColor = const Color(0xFFDC2626); // Rojo - retrasado/hoy
        nextHeatBgColor = const Color(0xFFFEE2E2);
      } else if (nextHeatDays <= 3) {
        nextHeatColor = const Color(0xFFD97706); // Naranja - próximo
        nextHeatBgColor = const Color(0xFFFEF3C7);
      } else {
        nextHeatColor = const Color(0xFF2E7D32); // Verde - normal
        nextHeatBgColor = const Color(0xFFDCFCE7);
      }
    }

    // Color del cluster de salud
    final clusterColor = Color(int.parse(cattle!.getClusterColor(clusterLabel).replaceFirst('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cattle!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Arete: ${cattle!.tag}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 🆕 Badge de cluster de salud
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: clusterColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: clusterColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  clusterLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: clusterColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🆕 Card de próximo celo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: nextHeatBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: nextHeatColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: nextHeatColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximo celo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: nextHeatColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextHeatText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: nextHeatColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                        cattle!.lote,
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
                        cattle!.age != null ? '${cattle!.age} años' : 'No registrada',
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
                      cattle!.weight != null ? '${cattle!.weight} kg' : 'No registrado',
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  'Historial (${combinedEvents.length})',
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

  Widget _buildSummaryTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          _buildInfoRow('Raza', cattle!.breed),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Género', cattle!.gender == 'female' ? 'Hembra' : 'Macho'),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Fecha de nacimiento', cattle!.formattedBirthDate),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Peso actual', cattle!.weight != null ? '${cattle!.weight} kg' : 'No registrado'),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Último parto', cattle!.formattedLastBirth),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Eventos de salud', '${healthEvents.length}'),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Eventos de celo', '${heatEvents.length}'),
        ],
      ),
    );
  }

  Widget _buildHistoryTabWithScroll() {
    if (combinedEvents.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
              const SizedBox(height: 8),
              Text(
                'Agrega vacunas y eventos de celo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: combinedEvents.length,
              itemBuilder: (context, index) {
                return _buildHistoryItem(combinedEvents[index]);
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
