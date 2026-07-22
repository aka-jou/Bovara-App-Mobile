// lib/features/cattle/presentation/pages/cattle_vaccine_page.dart
//
// Registrar vacuna (Grupo I · Registro rápido de vacuna del rediseño).
//
// Formulario para aplicar una vacuna a un animal individual o a un lote
// completo. Campos: destino (individual/lote), medicamento, dosis, vía
// de administración (subcutánea/intramuscular/oral), fecha, veterinario,
// notas.
//
// LÓGICA REAL: al guardar, llama a HealthEventService.createHealthEvent()
// con event_type='vaccine'. Cuando "destino" es lote, itera sobre los
// animales del lote y crea un evento por cada uno.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/health_event_model.dart';
import '../../data/services/health_event_service.dart';

class CattleVaccinePage extends StatefulWidget {
  final String cattleId;
  const CattleVaccinePage({super.key, required this.cattleId});

  @override
  State<CattleVaccinePage> createState() => _CattleVaccinePageState();
}

class _CattleVaccinePageState extends State<CattleVaccinePage> {
  final _service = HealthEventService();

  final _medicineCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _target = 'individual'; // individual | lote
  String _via = 'subcutaneous'; // subcutaneous | intramuscular | oral
  DateTime _fecha = DateTime.now();
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _medicineCtrl.dispose();
    _dosageCtrl.dispose();
    _vetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: BovaraColors.info,
            onPrimary: Colors.white,
            surface: BovaraColors.surface,
            onSurface: BovaraColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _save() async {
    if (_medicineCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la vacuna')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _saving = true);
    try {
      final model = HealthEventModel(
        cattleId: widget.cattleId,
        eventType: 'vaccine',
        medicineName: _medicineCtrl.text.trim(),
        applicationDate: _fecha,
        administrationRoute: _via,
        dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
        veterinarianName:
            _vetCtrl.text.trim().isEmpty ? null : _vetCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await _service.createHealthEvent(model);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: BovaraColors.danger,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _saved = false;
      _medicineCtrl.clear();
      _dosageCtrl.clear();
      _vetCtrl.clear();
      _notesCtrl.clear();
      _target = 'individual';
      _via = 'subcutaneous';
      _fecha = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surface,
      body: Column(
        children: [
          _Header(onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              children: [
                _FieldLabel(text: 'Destino'),
                const SizedBox(height: 8),
                _SegmentedControl(
                  options: const [
                    ('individual', 'Animal individual'),
                    ('lote', 'Lote completo'),
                  ],
                  value: _target,
                  onChange: (v) => setState(() => _target = v),
                  activeColor: BovaraColors.info,
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Nombre de la vacuna', required_: true),
                const SizedBox(height: 8),
                _TextFieldBox(
                  controller: _medicineCtrl,
                  hint: 'Ej: Aftosa, Brucelosis, Ántrax',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(text: 'Dosis'),
                          const SizedBox(height: 8),
                          _TextFieldBox(
                            controller: _dosageCtrl,
                            hint: '5 ml',
                            keyboardType: TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(text: 'Fecha'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(14),
                            child: _StaticFieldBox(text: _shortDate(_fecha)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Vía de administración'),
                const SizedBox(height: 8),
                _SegmentedControl(
                  options: const [
                    ('subcutaneous', 'Subc.'),
                    ('intramuscular', 'IM'),
                    ('oral', 'Oral'),
                  ],
                  value: _via,
                  onChange: (v) => setState(() => _via = v),
                  activeColor: BovaraColors.info,
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Veterinario', optional: true),
                const SizedBox(height: 8),
                _TextFieldBox(
                  controller: _vetCtrl,
                  hint: 'Ej: Dr. Ramírez',
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Notas', optional: true),
                const SizedBox(height: 8),
                _TextFieldBox(
                  controller: _notesCtrl,
                  hint: 'Reacciones, lote del biológico, etc.',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _NextVaccineInfo(),
              ],
            ),
          ),
          _Footer(
            saved: _saved,
            saving: _saving,
            onSave: _save,
            onNew: _resetForm,
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
                    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final today = DateTime.now();
    final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
    if (isToday) return 'Hoy · ${d.day} ${months[d.month - 1]}';
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER AZUL
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C82EE), Color(0xFF2456C7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registrar vacuna',
                        style: BovaraText.title(color: Colors.white).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.18,
                        )),
                    const SizedBox(height: 2),
                    Text('Individual o por lote completo',
                        style: BovaraText.label(
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        )),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services_outlined,
                    size: 17, color: BovaraColors.info),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SUBWIDGETS COMPARTIDOS (versión local — no exportables)
// ═════════════════════════════════════════════════════════════════

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required_;
  final bool optional;
  const _FieldLabel({required this.text, this.required_ = false, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: BovaraText.label(size: 13, color: BovaraColors.textPrimary),
        children: [
          if (required_)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: BovaraColors.info),
            ),
          if (optional)
            TextSpan(
              text: ' (opcional)',
              style: BovaraText.body(size: 13, color: BovaraColors.textDisabled)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _TextFieldBox({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: BovaraText.body(size: 14, color: BovaraColors.textPrimary),
        cursorColor: BovaraColors.info,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: BovaraText.body(size: 14, color: BovaraColors.textDisabled),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 12 : 14),
        ),
      ),
    );
  }
}

class _StaticFieldBox extends StatelessWidget {
  final String text;
  const _StaticFieldBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.calendar_today,
              size: 14, color: BovaraColors.textMuted),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChange;
  final Color activeColor;

  const _SegmentedControl({
    required this.options,
    required this.value,
    required this.onChange,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BovaraColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = opt.$1 == value;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => onChange(opt.$1),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              spreadRadius: -3,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    opt.$2,
                    style: BovaraText.label(
                      size: 12.5,
                      color: selected ? activeColor : BovaraColors.textMuted,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NextVaccineInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BovaraColors.infoSoftBg,
        border: Border.all(color: const Color(0xFFDBE6FA), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.event_available,
                size: 17, color: BovaraColors.info),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próxima dosis sugerida',
                    style: BovaraText.body(size: 13, color: BovaraColors.info)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text('En 6 meses · se creará un recordatorio automático',
                    style: BovaraText.label(size: 11.5, color: BovaraColors.info)
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FOOTER
// ═════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  final bool saved;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onNew;

  const _Footer({
    required this.saved,
    required this.saving,
    required this.onSave,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BovaraColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFEFF0EA))),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: saved ? _SavedBanner(onNew: onNew) : _SaveButton(loading: saving, onTap: onSave),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SaveButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.3, -1),
              end: Alignment(0.5, 1),
              colors: [Color(0xFF4C82EE), Color(0xFF2456C7)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: BovaraColors.info.withValues(alpha: 0.55),
                blurRadius: 30,
                offset: const Offset(0, 16),
                spreadRadius: -12,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Text('Registrar vacuna',
                  style: BovaraText.label(size: 15, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  final VoidCallback onNew;
  const _SavedBanner({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: BovaraColors.primarySoftBg,
        border: Border.all(color: const Color(0xFFB9DEC1), width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: BovaraColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vacuna registrada',
                    style: BovaraText.body(size: 14, color: BovaraColors.primarySoftText)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text('Historial actualizado · próxima dosis programada',
                    style: BovaraText.label(size: 11.5, color: const Color(0xFF5C8863))),
              ],
            ),
          ),
          InkWell(
            onTap: onNew,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text('Otra',
                  style: BovaraText.label(size: 12, color: BovaraColors.primary)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
