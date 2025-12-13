import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/cattle_model.dart';
import '../../data/services/cattle_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/application/app_state_repository.dart';

class CattleListPage extends StatefulWidget {
  const CattleListPage({super.key});

  @override
  State<CattleListPage> createState() => _CattleListPageState();
}

class _CattleListPageState extends State<CattleListPage> {
  final CattleService _cattleService = CattleService();
  int selectedTabIndex = 0;
  final TextEditingController searchController = TextEditingController();

  List<CattleModel> cattleList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCattle();
  }

  Future<void> _loadCattle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Debug: Verificar token
    final authService = AuthService();
    final token = await authService.getToken();
    print('🎫 Token al cargar vacas: ${token != null ? token.substring(0, 20) : "NULL"}...');

    try {
      final cattle = await _cattleService.getCattleList();
      setState(() {
        cattleList = cattle;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando vacas: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<String> get tabs {
    final lots = cattleList.map((c) => c.lote).toSet().toList();
    lots.sort();
    return ['Todos', ...lots];
  }

  List<CattleModel> get filteredCattle {
    if (selectedTabIndex == 0) return cattleList;
    final selectedLot = tabs[selectedTabIndex];
    return cattleList.where((cattle) => cattle.lote == selectedLot).toList();
  }

  Future<void> _createCattle(CattleModel newCattle) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );

      await _cattleService.createCattle(newCattle);

      if (mounted) Navigator.pop(context);

      await _loadCattle();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newCattle.name} agregada exitosamente'),
            backgroundColor: const Color(0xFF388E3C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddCattleForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCattleForm(
        onSave: _createCattle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Vacas del rancho',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCattle,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildRanchInfoCard(),
          const SizedBox(height: 16),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildCattleList()),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildRanchInfoCard() {
    // ✅ CORREGIDO: Usar ranchName en lugar de profile['ranch']
    final appState = context.watch<AppStateRepository>();
    final ranchName = appState.ranchName ?? 'Mi Rancho';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ranchName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${cattleList.length} vacas registradas',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF616161),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o arete',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFADAEBC),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xFF616161)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final isSelected = selectedTabIndex == index;
                return Padding(
                  padding: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
                  child: _buildFilterTab(
                    label: tabs[index],
                    isSelected: isSelected,
                    onTap: () => setState(() => selectedTabIndex = index),
                  ),
                );
              },
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF616161),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCattleList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                'Error al cargar las vacas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCattle,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredCattle.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.agriculture_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay vacas registradas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega tu primera vaca usando el botón de abajo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCattle.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCattleCard(filteredCattle[index]),
        );
      },
    );
  }

  Widget _buildCattleCard(CattleModel cattle) {
    return GestureDetector(
      onTap: () {
        context.push('/cattle/${cattle.id}', extra: cattle);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
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
                        '${cattle.name} – ${cattle.lote}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Arete: ${cattle.tag}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // ✅ CORREGIDO: withOpacity → withValues
                    color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    'Activa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Raza: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    Text(
                      cattle.breed,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'Último parto: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    Text(
                      cattle.formattedLastBirth,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ✅ CORREGIDO: withOpacity → withValues
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _showAddCattleForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            elevation: 6,
            // ✅ CORREGIDO: withOpacity → withValues
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text(
                'Agregar vaca',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// ============================================
// FORMULARIO PARA AGREGAR VACA
// ============================================

class AddCattleForm extends StatefulWidget {
  final Function(CattleModel) onSave;

  const AddCattleForm({
    super.key,
    required this.onSave,
  });

  @override
  State<AddCattleForm> createState() => _AddCattleFormState();
}

class _AddCattleFormState extends State<AddCattleForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController loteController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController lastBirthController = TextEditingController();

  String selectedGender = 'female';

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      DateTime? birthDate;
      DateTime? lastBirth;

      if (birthDateController.text.isNotEmpty) {
        final parts = birthDateController.text.split('/');
        birthDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (lastBirthController.text.isNotEmpty) {
        final parts = lastBirthController.text.split('/');
        lastBirth = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      final newCattle = CattleModel(
        id: '',
        name: nameController.text.toUpperCase(),
        lote: loteController.text,
        breed: breedController.text,
        gender: selectedGender,
        birthDate: birthDate,
        weight: double.tryParse(weightController.text),
        fechaUltimoParto: lastBirth,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(newCattle);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Agregar nueva vaca',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nombre de la vaca *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration(
                        hint: 'Ej: PALOMA',
                        icon: Icons.agriculture,
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Lote *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: loteController,
                      decoration: _inputDecoration(
                        hint: 'Ej: Lote A',
                        icon: Icons.folder,
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Raza *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: breedController,
                      decoration: _inputDecoration(
                        hint: 'Ej: Holstein',
                        icon: Icons.category,
                      ),
                      validator: (value) => value!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Género *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: _inputDecoration(
                        hint: 'Selecciona',
                        icon: Icons.wc,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'female', child: Text('Hembra')),
                        DropdownMenuItem(value: 'male', child: Text('Macho')),
                      ],
                      onChanged: (value) => setState(() => selectedGender = value!),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Fecha de nacimiento'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: birthDateController,
                      readOnly: true,
                      decoration: _inputDecoration(
                        hint: 'DD/MM/AAAA',
                        icon: Icons.cake,
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 730)),
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          birthDateController.text =
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Peso (kg)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        hint: 'Ej: 450',
                        icon: Icons.monitor_weight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Último parto (opcional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: lastBirthController,
                      readOnly: true,
                      decoration: _inputDecoration(
                        hint: 'DD/MM/AAAA',
                        icon: Icons.event,
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          lastBirthController.text =
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar vaca',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF222222),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADAEBC), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    loteController.dispose();
    breedController.dispose();
    birthDateController.dispose();
    weightController.dispose();
    lastBirthController.dispose();
    super.dispose();
  }
}
