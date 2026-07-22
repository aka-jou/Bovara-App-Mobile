// lib/features/cattle/presentation/pages/cattle_zeal_page.dart
//
// Registrar celo (Grupo I · Registro rápido de celo del rediseño).
//
// Formulario clínico rico para observación de monta. Calcula en tiempo
// real una probabilidad de celo con una heurística sencilla (reflejo de
// inmovilidad + veces montada + secreción + hinchazón + actividad +
// señales sociales) que se muestra en un modal tipo "Análisis de Bovi"
// con anillo circular animado antes de guardar.
//
// LÓGICA REAL: al confirmar, llama a HeatEventService.createHeatEvent()
// con un HeatEventModel armado desde el estado del form.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/ml_service.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/heat_event_model.dart';
import '../../data/services/heat_event_service.dart';

class CattleZealPage extends StatefulWidget {
  final String cattleId;
  const CattleZealPage({super.key, required this.cattleId});

  @override
  State<CattleZealPage> createState() => _CattleZealPageState();
}

class _CattleZealPageState extends State<CattleZealPage> {
  final _service = HeatEventService();
  final _ml = MlService();

  // Estado del formulario
  bool _inmovilidad = true;
  int _vecesMontada = 2;
  int _intentosMonta = 1;
  String _secrecion = 'cristalina'; // ninguna | cristalina | turbia | sangre
  String _hinchazon = 'leve'; // normal | leve | alta
  String _actividad = 'alta'; // baja | normal | alta | muy_alta
  final _social = <String, bool>{
    'mugidos': true,
    'nerviosismo': false,
    'monta_otras': true,
    'inquietud': true,
    'olfatea': false,
    'lame': false,
  };
  DateTime _fecha = DateTime.now();
  bool _saving = false;
  bool _saved = false;
  bool _analyzing = false;

  // Cálculo de probabilidad (heurística ponderada)
  int get _probability {
    var score = 0;
    if (_inmovilidad) score += 40; // signo de oro
    score += math.min(_vecesMontada * 8, 24);
    score += math.min(_intentosMonta * 4, 12);
    switch (_secrecion) {
      case 'cristalina':
        score += 15;
        break;
      case 'turbia':
        score += 6;
        break;
      case 'sangre':
        score += 8;
        break;
    }
    switch (_hinchazon) {
      case 'leve':
        score += 5;
        break;
      case 'alta':
        score += 10;
        break;
    }
    switch (_actividad) {
      case 'alta':
        score += 5;
        break;
      case 'muy_alta':
        score += 10;
        break;
    }
    final activeSocial = _social.values.where((v) => v).length;
    score += activeSocial * 2;
    return math.min(score, 99);
  }

  Color get _probColor {
    final p = _probability;
    if (p >= 70) return BovaraColors.celo;
    if (p >= 40) return BovaraColors.warning;
    return BovaraColors.textMuted;
  }

  String get _probVerdict {
    final p = _probability;
    if (p >= 80) return 'Celo confirmado';
    if (p >= 60) return 'Celo muy probable';
    if (p >= 40) return 'Celo posible';
    return 'Poco probable';
  }

  String get _probWindow {
    final p = _probability;
    if (p >= 70) {
      return 'Ventana de inseminación: próximas 12 h. Óptimo antes de la puesta de sol.';
    }
    if (p >= 40) {
      return 'Observa nuevamente en 6 h. Aún no es momento óptimo.';
    }
    return 'No hay signos suficientes. Programa una nueva revisión mañana.';
  }

  List<_Reason> get _probReasons {
    final reasons = <_Reason>[];
    if (_inmovilidad) {
      reasons.add(const _Reason(
        weight: '+40',
        title: 'Reflejo de inmovilidad',
        detail: 'El signo más confiable. Se deja montar sin resistencia.',
        color: BovaraColors.celo,
        bg: BovaraColors.celoSoftBg,
      ));
    }
    if (_vecesMontada >= 2) {
      reasons.add(_Reason(
        weight: '+${math.min(_vecesMontada * 8, 24)}',
        title: 'Montada $_vecesMontada veces',
        detail: 'Comportamiento receptivo repetido.',
        color: BovaraColors.info,
        bg: BovaraColors.infoSoftBg,
      ));
    }
    if (_secrecion == 'cristalina') {
      reasons.add(const _Reason(
        weight: '+15',
        title: 'Secreción cristalina',
        detail: 'Moco claro consistente con la fase estral.',
        color: BovaraColors.primary,
        bg: BovaraColors.primarySoftBg,
      ));
    }
    final socialCount = _social.values.where((v) => v).length;
    if (socialCount >= 3) {
      reasons.add(_Reason(
        weight: '+${socialCount * 2}',
        title: '$socialCount señales sociales',
        detail: 'Cambios conductuales típicos del celo.',
        color: BovaraColors.warning,
        bg: BovaraColors.warningSoftBg,
      ));
    }
    return reasons;
  }

  Future<void> _analyze() async {
    HapticFeedback.mediumImpact();

    // Muestra un spinner mientras el ml-service responde
    setState(() => _analyzing = true);
    HeatProbabilityResult? result;
    String? error;
    try {
      result = await _ml.predictHeatProbability(
        cattleId: widget.cattleId,
        inmovilidad: _inmovilidad,
        vecesMontada: _vecesMontada,
        intentosMonta: _intentosMonta,
        secrecion: _secrecion,
        hinchazon: _hinchazon,
        actividad: _actividad,
        social: _social,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }

    if (!mounted) return;
    if (error != null || result == null) {
      // Fallback: usa cálculo local si el ml-service falla, con banner de aviso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analizador ML no disponible, usando cálculo local. ${error ?? ''}'),
          backgroundColor: BovaraColors.warning,
        ),
      );
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _AnalysisModal(
          probability: _probability,
          color: _probColor,
          verdict: _probVerdict,
          window: _probWindow,
          reasons: _probReasons,
          source: 'fallback_local',
          onAdjust: () => Navigator.pop(ctx),
          onConfirm: () async {
            Navigator.pop(ctx);
            await _save();
          },
        ),
      );
      return;
    }

    // Convertir el resultado remoto al formato del modal
    final r = result;
    final remoteColor = _colorFor(r.probability);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnalysisModal(
        probability: r.probability,
        color: remoteColor,
        verdict: r.verdict,
        window: r.window,
        reasons: r.reasons.map(_reasonFromApi).toList(),
        source: r.source,
        onAdjust: () => Navigator.pop(ctx),
        onConfirm: () async {
          Navigator.pop(ctx);
          await _save();
        },
      ),
    );
  }

  Color _colorFor(int p) {
    if (p >= 70) return BovaraColors.celo;
    if (p >= 40) return BovaraColors.warning;
    return BovaraColors.textMuted;
  }

  _Reason _reasonFromApi(HeatReason r) {
    final (color, bg) = switch (r.color) {
      'celo' => (BovaraColors.celo, BovaraColors.celoSoftBg),
      'info' => (BovaraColors.info, BovaraColors.infoSoftBg),
      'primary' => (BovaraColors.primary, BovaraColors.primarySoftBg),
      'warning' => (BovaraColors.warning, BovaraColors.warningSoftBg),
      _ => (BovaraColors.textMuted, BovaraColors.surfaceMuted),
    };
    return _Reason(
      weight: r.weight,
      title: r.title,
      detail: r.detail,
      color: color,
      bg: bg,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final model = HeatEventModel(
        cattleId: widget.cattleId,
        heatDate: _fecha,
        allowsMounting: _inmovilidad,
        vaginalDischarge: _secrecion,
        vulvaSwelling: _hinchazon,
        comportamiento: _buildBehaviorSummary(),
        wasInseminated: false,
      );
      await _service.createHeatEvent(model);
      if (!mounted) return;
      HapticFeedback.selectionClick();
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

  String _buildBehaviorSummary() {
    final parts = <String>[
      'Montada $_vecesMontada · intentos $_intentosMonta',
      'Actividad $_actividad',
    ];
    final activeSocial = _social.entries
        .where((e) => e.value)
        .map((e) => e.key.replaceAll('_', ' '))
        .toList();
    if (activeSocial.isNotEmpty) parts.add(activeSocial.join(', '));
    return parts.join(' · ');
  }

  void _resetForm() {
    setState(() {
      _saved = false;
      _inmovilidad = true;
      _vecesMontada = 0;
      _intentosMonta = 0;
      _secrecion = 'ninguna';
      _hinchazon = 'normal';
      _actividad = 'normal';
      for (final k in _social.keys) {
        _social[k] = false;
      }
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
                _FieldLabel(text: 'Animal'),
                const SizedBox(height: 8),
                _AnimalCard(cattleId: widget.cattleId),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(text: 'Fecha'),
                          const SizedBox(height: 8),
                          _StaticFieldBox(text: 'Hoy · ${_shortDate(_fecha)}'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(text: 'Hora'),
                          const SizedBox(height: 8),
                          _StaticFieldBox(text: _shortTime(_fecha)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InmovilidadCard(
                  value: _inmovilidad,
                  onChanged: (v) => setState(() => _inmovilidad = v),
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Comportamiento de monta'),
                const SizedBox(height: 8),
                _StepperGroup(children: [
                  _StepperRow(
                    label: 'Veces montada por otras',
                    value: _vecesMontada,
                    onDec: () => setState(() =>
                        _vecesMontada = math.max(0, _vecesMontada - 1)),
                    onInc: () => setState(() => _vecesMontada++),
                  ),
                  _StepperRow(
                    label: 'Intentos de monta',
                    value: _intentosMonta,
                    onDec: () => setState(() =>
                        _intentosMonta = math.max(0, _intentosMonta - 1)),
                    onInc: () => setState(() => _intentosMonta++),
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Secreción vaginal'),
                const SizedBox(height: 8),
                _SecretionGrid(
                  value: _secrecion,
                  onChange: (v) => setState(() => _secrecion = v),
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Hinchazón vulvar'),
                const SizedBox(height: 8),
                _SegmentedControl(
                  options: const [
                    ('normal', 'Normal'),
                    ('leve', 'Leve'),
                    ('alta', 'Alta'),
                  ],
                  value: _hinchazon,
                  onChange: (v) => setState(() => _hinchazon = v),
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Nivel de actividad'),
                const SizedBox(height: 8),
                _SegmentedControl(
                  options: const [
                    ('baja', 'Baja'),
                    ('normal', 'Normal'),
                    ('alta', 'Alta'),
                    ('muy_alta', 'Muy alta'),
                  ],
                  value: _actividad,
                  onChange: (v) => setState(() => _actividad = v),
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Señales sociales'),
                const SizedBox(height: 8),
                _SocialChips(
                  values: _social,
                  onToggle: (k) => setState(() => _social[k] = !_social[k]!),
                ),
              ],
            ),
          ),
          _Footer(
            saved: _saved,
            saving: _saving || _analyzing,
            onAnalyze: _analyze,
            onNew: _resetForm,
          ),
        ],
      ),
    );
  }

  String _probHint() {
    final p = _probability;
    if (p >= 70) return 'Signos claros. Considera inseminar en las próximas horas.';
    if (p >= 40) return 'Signos parciales. Registra ahora y observa en 6 h.';
    return 'Muy pocos signos. Revisa nuevamente mañana.';
  }

  String _shortDate(DateTime d) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
                    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _shortTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER ROSA
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
          colors: [Color(0xFFE0559B), Color(0xFFC23368)],
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
                    Text('Registrar celo',
                        style: BovaraText.title(color: Colors.white).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.18,
                        )),
                    const SizedBox(height: 2),
                    Text('Observación de monta · 1 minuto',
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
                child: const Icon(Icons.favorite_rounded,
                    size: 17, color: BovaraColors.celo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SUBWIDGETS
// ═════════════════════════════════════════════════════════════════

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: BovaraText.label(size: 13, color: BovaraColors.textPrimary));
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
      child: Text(text,
          style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final String cattleId;
  const _AnimalCard({required this.cattleId});

  @override
  Widget build(BuildContext context) {
    // Corto los primeros 3 chars del UUID como "arete"
    final tag = cattleId.replaceAll('-', '').substring(0, 3).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: BovaraColors.celoSoftBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(tag,
                style: BovaraText.label(size: 13, color: BovaraColors.celoSoftText)
                    .copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vaca seleccionada',
                    style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text('ID: $tag…',
                    style: BovaraText.label(size: 12, color: BovaraColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InmovilidadCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InmovilidadCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final borderColor = value ? BovaraColors.celo : BovaraColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reflejo de inmovilidad',
                    style: BovaraText.body(size: 14, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text('¿Se deja montar? · signo de oro',
                    style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: BovaraColors.celo,
          ),
        ],
      ),
    );
  }
}

class _StepperGroup extends StatelessWidget {
  final List<Widget> children;
  const _StepperGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(children: children),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final bool isLast;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF2F3ED), width: 1),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: BovaraText.body(size: 13, color: BovaraColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          _CircleBtn(icon: Icons.remove, onTap: onDec, isNegative: true),
          SizedBox(
            width: 32,
            child: Center(
              child: Text('$value',
                  style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  )),
            ),
          ),
          _CircleBtn(icon: Icons.add, onTap: onInc, isNegative: false),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isNegative;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isNegative ? BovaraColors.surfaceAlt : BovaraColors.primarySoftBg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon,
              size: 16,
              color: isNegative
                  ? BovaraColors.textSecondary
                  : BovaraColors.primarySoftText),
        ),
      ),
    );
  }
}

class _SecretionGrid extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;

  const _SecretionGrid({required this.value, required this.onChange});

  static const _options = <(String, String, Color)>[
    ('ninguna', 'Ninguna', Color(0xFFD8DCD4)),
    ('cristalina', 'Cristalina', Color(0xFF9CC4F2)),
    ('turbia', 'Turbia', Color(0xFFC9B87A)),
    ('sangre', 'Sangre', Color(0xFFD6453C)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final key = opt.$1;
        final label = opt.$2;
        final drop = opt.$3;
        final selected = key == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onChange(key),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? BovaraColors.celoSoftBg : Colors.white,
                  border: Border.all(
                    color: selected ? BovaraColors.celo : BovaraColors.border,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícono de gota (rotado)
                    Transform.rotate(
                      angle: -math.pi / 4,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: drop,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(999),
                            topRight: Radius.circular(999),
                            bottomLeft: Radius.zero,
                            bottomRight: Radius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(label,
                        style: BovaraText.label(
                          size: 11,
                          color: BovaraColors.textPrimary,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChange;

  const _SegmentedControl({
    required this.options,
    required this.value,
    required this.onChange,
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
                      color: selected
                          ? BovaraColors.textPrimary
                          : BovaraColors.textMuted,
                    ),
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

class _SocialChips extends StatelessWidget {
  final Map<String, bool> values;
  final ValueChanged<String> onToggle;

  const _SocialChips({required this.values, required this.onToggle});

  static const _labels = <String, String>{
    'mugidos': 'Mugidos',
    'nerviosismo': 'Nerviosismo',
    'monta_otras': 'Monta a otras',
    'inquietud': 'Inquietud',
    'olfatea': 'Olfatea genitales',
    'lame': 'Lame genitales',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _labels.entries.map((e) {
        final key = e.key;
        final label = e.value;
        final selected = values[key] == true;
        return InkWell(
          onTap: () => onToggle(key),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? BovaraColors.celoSoftBg : Colors.white,
              border: Border.all(
                color: selected ? BovaraColors.celo : BovaraColors.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: BovaraText.label(
                size: 12.5,
                color: selected
                    ? BovaraColors.celoSoftText
                    : BovaraColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProbabilityCard extends StatelessWidget {
  final int probability;
  final Color color;
  final String hint;

  const _ProbabilityCard({
    required this.probability,
    required this.color,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text('Probabilidad de celo',
                    style: BovaraText.body(size: 13.5, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
              Text('$probability%',
                  style: BovaraText.title(color: color).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: probability / 100,
              backgroundColor: BovaraColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(hint,
              style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted)),
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
  final VoidCallback onAnalyze;
  final VoidCallback onNew;

  const _Footer({
    required this.saved,
    required this.saving,
    required this.onAnalyze,
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
      child: saved ? _SavedBanner(onNew: onNew) : _AnalyzeButton(loading: saving, onTap: onAnalyze),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _AnalyzeButton({required this.loading, required this.onTap});

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
              colors: [Color(0xFFE0559B), BovaraColors.celo],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: BovaraColors.celo.withValues(alpha: 0.55),
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
              : Text('Analizar y ver resultado',
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
                Text('Celo registrado',
                    style: BovaraText.body(size: 14, color: BovaraColors.primarySoftText)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text('Guardado · sincronizado con tu hato',
                    style: BovaraText.label(size: 11.5, color: const Color(0xFF5C8863))),
              ],
            ),
          ),
          InkWell(
            onTap: onNew,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text('Otro',
                  style: BovaraText.label(size: 12, color: BovaraColors.primary)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODAL DE ANÁLISIS DE BOVI
// ═════════════════════════════════════════════════════════════════

class _Reason {
  final String weight;
  final String title;
  final String detail;
  final Color color;
  final Color bg;
  const _Reason({
    required this.weight,
    required this.title,
    required this.detail,
    required this.color,
    required this.bg,
  });
}

class _AnalysisModal extends StatelessWidget {
  final int probability;
  final Color color;
  final String verdict;
  final String window;
  final List<_Reason> reasons;
  final String source;
  final VoidCallback onAdjust;
  final VoidCallback onConfirm;

  const _AnalysisModal({
    required this.probability,
    required this.color,
    required this.verdict,
    required this.window,
    required this.reasons,
    required this.source,
    required this.onAdjust,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: BovaraColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: BovaraColors.borderMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BovaraColors.primarySoftBg,
                    border: Border.all(color: const Color(0xFFCBE3CE), width: 1.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.smart_toy_rounded,
                      size: 20, color: BovaraColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Análisis de Bovi',
                          style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          )),
                      Text(
                        source == 'fallback_local'
                            ? 'Modo local (sin red ML)'
                            : 'Análisis del servidor · $source',
                        style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RingCard(probability: probability, color: color, verdict: verdict, window: window),
            const SizedBox(height: 16),
            Text('POR QUÉ ESTE RESULTADO',
                style: BovaraText.label(size: 11, color: BovaraColors.textMuted)
                    .copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            if (reasons.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Ningún signo fuerte detectado. Registra más observaciones o revisa nuevamente en unas horas.',
                  style: BovaraText.body(size: 13, color: BovaraColors.textSecondary),
                ),
              )
            else
              ...reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReasonCard(reason: r),
                  )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAdjust,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: BovaraColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Ajustar datos',
                        style: BovaraText.label(size: 14, color: BovaraColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onConfirm,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(-0.3, -1),
                            end: Alignment(0.5, 1),
                            colors: [Color(0xFFE0559B), BovaraColors.celo],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: BovaraColors.celo.withValues(alpha: 0.55),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text('Confirmar y guardar',
                            style: BovaraText.label(size: 14, color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingCard extends StatelessWidget {
  final int probability;
  final Color color;
  final String verdict;
  final String window;

  const _RingCard({
    required this.probability,
    required this.color,
    required this.verdict,
    required this.window,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 8),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _RingPainter(probability: probability, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$probability%',
                        style: BovaraText.title(color: color).copyWith(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        )),
                    const SizedBox(height: 2),
                    Text('CELO',
                        style: BovaraText.label(size: 9.5, color: BovaraColors.textMuted)
                            .copyWith(letterSpacing: 0.9, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verdict,
                    style: BovaraText.body(size: 15, color: color)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(window,
                    style: BovaraText.body(size: 12.5, color: BovaraColors.textSecondary)
                        .copyWith(fontWeight: FontWeight.w500, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int probability;
  final Color color;
  _RingPainter({required this.probability, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;

    // Anillo de fondo
    final bgPaint = Paint()
      ..color = const Color(0xFFF1E4EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(center, radius, bgPaint);

    // Anillo de progreso
    final progPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final sweep = (probability / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.probability != probability || old.color != color;
}

class _ReasonCard extends StatelessWidget {
  final _Reason reason;
  const _ReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: reason.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(reason.weight,
                style: BovaraText.label(size: 11, color: reason.color)
                    .copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason.title,
                    style: BovaraText.body(size: 12.5, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text(reason.detail,
                    style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted)
                        .copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
