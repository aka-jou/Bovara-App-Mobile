// lib/features/cattle/presentation/pages/cattle_zeal_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CattleZealPage extends StatefulWidget {
  final String cattleId;

  const CattleZealPage({
    super.key,
    required this.cattleId,
  });

  @override
  State<CattleZealPage> createState() => _CattleZealPageState();
}

class _CattleZealPageState extends State<CattleZealPage> {
  bool reflejoInmovilidad = true;
  String secrecionVaginal = 'Turbio';
  String hinchazonVulvar = 'Normal';
  List<String> comportamiento = ['Mugidos', 'Nerviosismo'];

  Map<String, String> get cattleData {
    return {
      'name': 'LUNA',
      'id': widget.cattleId,
      'lot': 'Lote A',
    };
  }

  void _saveAndAnalyze() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro guardado exitosamente'),
        backgroundColor: Color(0xFF388E3C),
      ),
    );
    context.pop();
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
                      'Registro de Celo',
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

          Expanded(
            child: Column(
              children: [
                // CARD DE INFORMACIÓN - ESTÁTICA
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E3C).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Color(0xFF388E3C),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cattleData['name']!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID:${cattleData['id']} • ${cattleData['lot']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // CONTENIDO SCROLLABLE
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // Reflejo de Inmovilidad
                        Container(
                          width: double.infinity, // ✅ Ancho completo
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
                                'Reflejo de Inmovilidad',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Se deja montar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  Switch(
                                    value: reflejoInmovilidad,
                                    onChanged: (value) {
                                      setState(() {
                                        reflejoInmovilidad = value;
                                      });
                                    },
                                    activeColor: const Color(0xFF388E3C),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Secreción Vaginal
                        Container(
                          width: double.infinity, // ✅ Ancho completo
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
                                'Secreción Vaginal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSecrecionOption('Seco'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSecrecionOption('Turbio'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSecrecionOption('Cristalino'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hinchazón Vulvar
                        Container(
                          width: double.infinity, // ✅ Ancho completo
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
                                'Hinchazón Vulvar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildHinchazonOption('Normal'),
                                  ),
                                  Expanded(
                                    child: _buildHinchazonOption('Leve'),
                                  ),
                                  Expanded(
                                    child: _buildHinchazonOption('Alta'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ✅ Comportamiento - ANCHO COMPLETO
                        Container(
                          width: double.infinity, // ✅ ESTO ERA LO QUE FALTABA
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
                                'Comportamiento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildComportamientoChip('Mugidos'),
                                  _buildComportamientoChip('Nerviosismo'),
                                  _buildComportamientoChip('Monta a otras'),
                                  _buildComportamientoChip('Inquietud'),
                                  _buildComportamientoChip('Olfatea'),
                                  _buildComportamientoChip('Lame genitales'),
                                ],
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

          // Footer
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Probabilidad de Celo:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _calculateProbability(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF388E3C),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(_calculateProbability() * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveAndAnalyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
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
                            'GUARDAR Y ANALIZAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProbability() {
    double probability = 0.0;

    if (reflejoInmovilidad) probability += 0.40;
    if (secrecionVaginal == 'Cristalino') probability += 0.20;
    if (secrecionVaginal == 'Turbio') probability += 0.10;
    if (hinchazonVulvar == 'Alta') probability += 0.15;
    if (hinchazonVulvar == 'Leve') probability += 0.10;

    probability += (comportamiento.length * 0.05);

    return probability.clamp(0.0, 1.0);
  }

  Widget _buildSecrecionOption(String option) {
    final isSelected = secrecionVaginal == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          secrecionVaginal = option;
        });
      },
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF388E3C) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop,
              color: isSelected ? const Color(0xFF388E3C) : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              option,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF374151) : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHinchazonOption(String option) {
    final isSelected = hinchazonVulvar == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          hinchazonVulvar = option;
        });
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF388E3C).withOpacity(0.05)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF388E3C) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: option == 'Normal'
              ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
              : option == 'Alta'
              ? const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          option,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF388E3C) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildComportamientoChip(String label) {
    final isSelected = comportamiento.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            comportamiento.remove(label);
          } else {
            comportamiento.add(label);
          }
        });
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF388E3C) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Color(0xFF388E3C),
                size: 14,
              )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF388E3C) : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
