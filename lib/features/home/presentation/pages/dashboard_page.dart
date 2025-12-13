// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/application/app_state_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateRepository>();

    final nombre = appState.userName ?? 'Ganadero Bovara';
    final rol = appState.userRole ?? 'Ganadero / Propietario';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildExpandableFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildUserBanner(nombre, rol),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildRecentRecordsCard(),
                      const SizedBox(height: 16),
                      // ✅ CARD DE ALERTAS ELIMINADA
                      // ✅ CARD DE PRÓXIMAS TAREAS CON NAVEGACIÓN
                      _buildUpcomingTasksCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Overlay cuando el FAB está expandido
          if (_isFabExpanded)
            GestureDetector(
              onTap: _toggleFab,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- APPBAR ----------

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2E7D32),
      centerTitle: false,
      title: const Text(
        'Bovara',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2E7D32),
        ),
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 24,
                color: Colors.grey[700],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            context.go('/notifications');
          },
        ),
        InkWell(
          onTap: () {
            context.go('/account');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 18,
              color: Color(0xFF616161),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- FAB EXPANDIBLE ----------

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isFabExpanded) ...[
          _buildFabOption(
            icon: Icons.pets,
            label: 'Agregar vaca',
            onPressed: () {
              _toggleFab();
              context.push('/cattle/add');
            },
          ),
          const SizedBox(height: 12),
          _buildFabOption(
            icon: Icons.favorite,
            label: 'Calcular celo',
            onPressed: () {
              _toggleFab();
              context.push('/cattle/heat-calculator');
            },
          ),
          const SizedBox(height: 12),
          _buildFabOption(
            icon: Icons.medical_services,
            label: 'Registrar vacuna',
            onPressed: () {
              _toggleFab();
              context.push('/cattle/vaccine');
            },
          ),
          const SizedBox(height: 16),
        ],
        // FAB principal
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: RotationTransition(
            turns: _rotationAnimation,
            child: IconButton(
              icon: Icon(
                _isFabExpanded ? Icons.close : Icons.add,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _toggleFab,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
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
    );
  }

  // ---------- BANNER USUARIO ----------

  Widget _buildUserBanner(String userName, String role) {
    return Container(
      height: 108,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hola, $userName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA5D6A7),
                ),
              ),
            ],
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- TARJETAS ----------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.content_paste_rounded,
              color: Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de hoy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pendientes de hoy: 3 tareas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pesajes, vacunas, revisiones',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.content_paste_outlined,
                  color: Color(0xFF8D6E63),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Registros recientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecordItem('Pesaje Lote A', 'Hoy 10:00', true),
          _buildRecordItem('Vacuna Lote B', 'Ayer', true),
          _buildRecordItem('Revisión Lote C', 'Hace 2 días', false),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.push('/cattle');
            },
            child: const Text(
              'Ver todos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String title, String time, bool showDivider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: Colors.grey[100]!))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF388E3C),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CARD DE PRÓXIMAS TAREAS - AHORA ES CLICKEABLE
  Widget _buildUpcomingTasksCard() {
    return InkWell(
      onTap: () {
        context.go('/reminders');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Próximas tareas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                // ✅ Icono de flecha para indicar que es clickeable
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTaskItem(
              'MAR',
              '15',
              'Vacunar Lote C',
              'Mañana 8:00',
              const Color(0xFF2E7D32),
              true,
            ),
            _buildTaskItem(
              'MIÉ',
              '16',
              'Pesaje Lote B',
              'Miércoles 9:30',
              const Color(0xFF8D6E63),
              true,
            ),
            _buildTaskItem(
              'JUE',
              '17',
              'Revisión veterinaria',
              'Jueves 10:00',
              const Color(0xFF388E3C),
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(
      String month,
      String day,
      String title,
      String time,
      Color color,
      bool showDivider,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: Colors.grey[100]!))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BOTTOM NAV ----------

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Inicio', 0),
          _buildNavItem(Icons.content_paste_outlined, 'Registros', 1),
          const SizedBox(width: 56),
          _buildNavItem(Icons.calendar_today_outlined, 'Recordatorios', 2),
          _buildNavItem(Icons.chat_bubble_outline, 'Asistente', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/cattle');
            break;
          case 2:
            context.go('/reminders');
            break;
          case 3:
            context.push('/assistant');
            break;
        }
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2E7D32)
                    : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
