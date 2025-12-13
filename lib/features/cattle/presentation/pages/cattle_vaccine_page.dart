// lib/features/cattle/presentation/pages/cattle_vaccine_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CattleVaccinePage extends StatefulWidget {
  final String cattleId;

  const CattleVaccinePage({
    super.key,
    required this.cattleId,
  });

  @override
  State<CattleVaccinePage> createState() => _CattleVaccinePageState();
}

class _CattleVaccinePageState extends State<CattleVaccinePage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _diseaseController = TextEditingController();
  final _medicineController = TextEditingController();

  // Valores del formulario
  DateTime? _applicationDate;
  String _administrationRoute = 'Subcutánea';
  DateTime? _nextDoseDate;
  DateTime? _treatmentEndDate;

  @override
  void dispose() {
    _diseaseController.dispose();
    _medicineController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF388E3C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF222222),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'application':
            _applicationDate = picked;
            break;
          case 'nextDose':
            _nextDoseDate = picked;
            break;
          case 'treatmentEnd':
            _treatmentEndDate = picked;
            break;
        }
      });
    }
  }

  void _saveVaccineRecord() {
    if (_formKey.currentState!.validate()) {
      if (_applicationDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona la fecha de aplicación'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      // TODO: Aquí guardarías los datos en tu backend
      final vaccineData = {
        'cattleId': widget.cattleId,
        'disease': _diseaseController.text,
        'medicine': _medicineController.text,
        'applicationDate': _applicationDate!.toIso8601String(),
        'administrationRoute': _administrationRoute,
        'nextDoseDate': _nextDoseDate?.toIso8601String(),
        'treatmentEndDate': _treatmentEndDate?.toIso8601String(),
      };

      print('Datos de vacuna: $vaccineData');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vacuna registrada exitosamente'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );

      context.pop();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
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
                      'Registrar Vacuna',
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
          ),

          // Formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre de la enfermedad
                    _buildSectionTitle('Información del tratamiento'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _diseaseController,
                      label: 'Nombre de la enfermedad',
                      hint: 'Ej: Brucelosis, Fiebre Aftosa',
                      icon: Icons.medical_information,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Este campo es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre del medicamento
                    _buildTextField(
                      controller: _medicineController,
                      label: 'Nombre del medicamento',
                      hint: 'Ej: Vacuna Triple Bovina',
                      icon: Icons.vaccines,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Este campo es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Fecha de aplicación
                    _buildSectionTitle('Fechas'),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Fecha de aplicación',
                      value: _formatDate(_applicationDate),
                      icon: Icons.calendar_today,
                      onTap: () => _selectDate(context, 'application'),
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Vía de administración
                    _buildSectionTitle('Vía de administración'),
                    const SizedBox(height: 16),
                    _buildAdministrationRouteSelector(),
                    const SizedBox(height: 24),

                    // Programación
                    _buildSectionTitle('Programación de seguimiento'),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Próxima dosis (opcional)',
                      value: _formatDate(_nextDoseDate),
                      icon: Icons.event_repeat,
                      onTap: () => _selectDate(context, 'nextDose'),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Finalización del tratamiento (opcional)',
                      value: _formatDate(_treatmentEndDate),
                      icon: Icons.event_available,
                      onTap: () => _selectDate(context, 'treatmentEnd'),
                    ),
                    const SizedBox(height: 24),

                    // Info adicional
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Las fechas programadas se agregarán automáticamente al calendario de recordatorios',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón guardar
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
                  onPressed: _saveVaccineRecord,
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
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Guardar registro',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF222222),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF388E3C)),
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
            borderSide: const BorderSide(color: Color(0xFF388E3C), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF388E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF388E3C), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isRequired)
                        const Text(
                          ' *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: value == 'Seleccionar fecha'
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdministrationRouteSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRouteOption(
            'Subcutánea',
            'Debajo de la piel',
            Icons.arrow_downward,
            _administrationRoute == 'Subcutánea',
                () => setState(() => _administrationRoute = 'Subcutánea'),
          ),
          const Divider(height: 1, indent: 56),
          _buildRouteOption(
            'Intramuscular',
            'En el músculo',
            Icons.flash_on,
            _administrationRoute == 'Intramuscular',
                () => setState(() => _administrationRoute = 'Intramuscular'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteOption(
      String title,
      String subtitle,
      IconData icon,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF388E3C).withOpacity(0.1)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF388E3C) : const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF222222) : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF388E3C),
                size: 24,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
