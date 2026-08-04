// lib/features/cattle/presentation/pages/cattle_detail_page.dart
//
// Detalle de vaca (Grupo E · Detalle del rediseño).
//
// Estructura:
//   - Header verde con gradient: botón atrás + "Vaca #405" + "editar".
//   - Card superpuesta (marginTop negativo) con foto grande + chips
//     (Holstein/Hembra/En celo) + trio de stats (peso/edad/partos).
//   - Card "Ficha del animal": tabla de key/value.
//   - Card rosa "Estado reproductivo" (solo si female): banner interno con
//     ventana de inseminación + CTA rosa "Registrar inseminación".
//   - Card "Evolución de peso": mini gráfico de barras.
//   - Card "Historial de eventos": timeline con dots verticales.
//
// LÓGICA: recibe CattleModel via `extra` del router (para renderizar rápido)
// y luego refresca los detalles desde la API.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/widgets/bovara_buttons.dart';
import '../../data/models/cattle_model.dart';
import '../../data/services/cattle_service.dart';
import '../../data/services/health_event_service.dart';
import '../../data/services/heat_event_service.dart';
import '../../data/models/health_event_model.dart';
import '../../data/models/heat_event_model.dart';

class CattleDetailPage extends StatefulWidget {
  final String cattleId;
  final CattleModel? preloaded;

  const CattleDetailPage({
    super.key,
    required this.cattleId,
    this.preloaded,
  });

  @override
  State<CattleDetailPage> createState() => _CattleDetailPageState();
}

class _CattleDetailPageState extends State<CattleDetailPage> {
  final _service = CattleService();
  final _heatService = HeatEventService();
  CattleModel? _cattle;
  HeatEventModel? _latestHeat;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cattle = widget.preloaded;
    if (widget.preloaded == null) _loading = true;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _service.getCattleById(widget.cattleId);
      HeatEventModel? latestHeat;
      try {
        final heats = await _heatService.getHeatEventsByCattle(widget.cattleId);
        if (heats.isNotEmpty) {
          heats.sort((a, b) => b.heatDate.compareTo(a.heatDate));
          latestHeat = heats.first;
        }
      } catch (_) {
        // Si falla el historial de celo, seguimos mostrando el resto.
      }
      if (!mounted) return;
      setState(() {
        _cattle = fresh;
        _latestHeat = latestHeat;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Registra un parto: suma 1 al contador de partos de la madre y,
  /// opcionalmente, registra a la cría como animal nuevo ligado a ella
  /// (misma logica que la herramienta register_birth de Bovi, pero
  /// desde la app usando los endpoints genericos ya existentes).
  Future<void> _registerBirth(CattleModel mother) async {
    final result = await showModalBottomSheet<_BirthFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _BirthForm(motherLote: mother.lote),
    );
    if (result == null || !mounted) return;

    try {
      await _service.updateCattle(mother.id, {
        'num_partos': mother.numPartos + 1,
        'fecha_ultimo_parto': result.birthDate.toIso8601String().split('T')[0],
      });

      if (result.registerCalf) {
        final now = DateTime.now();
        await _service.createCattle(CattleModel(
          id: '',
          name: result.calfName!,
          lote: result.calfLote!,
          breed: mother.breed,
          gender: result.calfGender!,
          birthDate: result.birthDate,
          motherCattleId: mother.id,
          createdAt: now,
          updatedAt: now,
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.registerCalf
              ? 'Parto registrado y cría agregada al hato'
              : 'Parto registrado'),
          backgroundColor: BovaraColors.primary,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar el parto: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: BovaraColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cattle = _cattle;
    if (cattle == null && _loading) {
      return const Scaffold(
        backgroundColor: BovaraColors.surfaceAlt,
        body: Center(child: CircularProgressIndicator(color: BovaraColors.primary)),
      );
    }
    if (cattle == null) {
      return Scaffold(
        backgroundColor: BovaraColors.surfaceAlt,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 42, color: BovaraColors.textMuted),
                const SizedBox(height: 12),
                Text('No se pudo cargar la información del animal.',
                    textAlign: TextAlign.center,
                    style: BovaraText.body(size: 14, color: BovaraColors.textSecondary)),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => context.go('/cattle'),
                  child: Text('Volver',
                      style: BovaraText.label(size: 13, color: BovaraColors.primary)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(cattle: cattle, onEdited: _refresh)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                children: [
                  _HeroCard(cattle: cattle, onPhotoChanged: _refresh),
                  const SizedBox(height: 14),
                  _AnimalSheet(cattle: cattle),
                  const SizedBox(height: 14),
                  _QuickActionsRow(
                    onVaccine: () =>
                        context.push('/cattle/${cattle.id}/vaccine', extra: cattle),
                    isFemale: cattle.gender.toLowerCase() == 'female',
                    onBirth: () => _registerBirth(cattle),
                  ),
                  if (cattle.gender.toLowerCase() == 'female') ...[
                    const SizedBox(height: 14),
                    _ReproStatusCard(
                      latestHeat: _latestHeat,
                      onRegisterHeat: () =>
                          context.push('/cattle/${cattle.id}/zeal', extra: cattle),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _EventsHistoryCard(cattleId: cattle.id),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER VERDE
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final CattleModel cattle;
  final VoidCallback onEdited;
  const _Header({required this.cattle, required this.onEdited});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BovaraColors.primary, Color(0xFF1B5C2C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.go('/cattle'),
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
                    Text(
                      '${cattle.arete} · ${cattle.name}',
                      style: BovaraText.title(color: Colors.white).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Lote: ${cattle.lote}',
                      style: BovaraText.label(
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () async {
                    final updated = await context.push<bool>('/cattle/new', extra: cattle);
                    if (updated == true) onEdited();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HERO CARD (foto + chips + stats)
// ═════════════════════════════════════════════════════════════════

class _HeroCard extends StatefulWidget {
  final CattleModel cattle;
  final VoidCallback onPhotoChanged;
  const _HeroCard({required this.cattle, required this.onPhotoChanged});

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  final _cattleService = CattleService();
  bool _uploading = false;

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploading = true);
      final url = await _cloudinary.uploadImage(File(picked.path));
      await _cattleService.updateCattle(widget.cattle.id, {'photo_url': url});

      if (!mounted) return;
      setState(() => _uploading = false);
      widget.onPhotoChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No pude subir la foto: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: BovaraColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cattle = widget.cattle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4C000000),
            blurRadius: 34,
            offset: Offset(0, 14),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Slot de foto — muestra la foto real de Cloudinary si existe,
          // y siempre deja tocar para subir/cambiarla (necesario porque
          // si la vaca se registró por chat con Bovi, no tiene foto: Bovi
          // no puede acceder a la galería del celular).
          GestureDetector(
            onTap: _uploading ? null : _pickAndUploadPhoto,
            child: Container(
              height: 168,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: BovaraColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BovaraColors.border, width: 1),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cattle.photoUrl != null && cattle.photoUrl!.isNotEmpty)
                    Image.network(
                      cattle.photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: BovaraColors.primary,
                                    strokeWidth: 2.4,
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_outlined,
                                size: 28, color: BovaraColors.textMuted),
                            const SizedBox(height: 6),
                            Text('No se pudo cargar la foto',
                                style: BovaraText.label(
                                  size: 12,
                                  color: BovaraColors.textMuted,
                                )),
                          ],
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              size: 28, color: BovaraColors.textMuted),
                          const SizedBox(height: 6),
                          Text(
                            'Toca para agregar foto',
                            style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  if (_uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                      ),
                    )
                  else
                    // Botón de cámara siempre visible, para cambiar la
                    // foto aunque ya exista una.
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 15, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: cattle.weight != null ? cattle.weight!.toStringAsFixed(0) : '—',
                  unit: cattle.weight != null ? 'kg' : '',
                  label: 'Peso actual',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  value: cattle.age?.toString() ?? '—',
                  unit: cattle.age != null ? (cattle.age == 1 ? 'año' : 'años') : '',
                  label: 'Edad',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  value: '${cattle.numPartos}',
                  unit: '',
                  label: 'Partos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _HeroStat({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: value,
              style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
              children: unit.isEmpty
                  ? null
                  : [
                      TextSpan(
                        text: ' $unit',
                        style: BovaraText.label(size: 11, color: BovaraColors.textMuted),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: BovaraText.label(size: 10.5, color: BovaraColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FICHA DEL ANIMAL
// ═════════════════════════════════════════════════════════════════

class _AnimalSheet extends StatelessWidget {
  final CattleModel cattle;
  const _AnimalSheet({required this.cattle});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ficha del animal',
              style: BovaraText.heading().copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _SheetRow(
            label: 'Arete',
            value: cattle.arete,
            isMono: true,
          ),
          _SheetRow(
            label: 'Nombre',
            value: cattle.name,
          ),
          _SheetRow(
            label: 'Lote',
            value: cattle.lote,
          ),
          _SheetRow(
            label: 'Nacimiento',
            value: cattle.birthDate != null
                ? '${cattle.formattedBirthDate} · ${cattle.age} ${cattle.age == 1 ? 'año' : 'años'}'
                : 'Sin registro',
          ),
          if (cattle.gender.toLowerCase() == 'female')
            _SheetRow(
              label: 'Partos',
              value: '${cattle.numPartos}',
            ),
          _SheetRow(
            label: 'Raza',
            value: cattle.breed,
          ),
          _SheetRow(
            label: 'Sexo',
            value: cattle.gender.toLowerCase() == 'female' ? 'Hembra' : 'Macho',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final bool isLast;
  final Color? valueColor;

  const _SheetRow({
    required this.label,
    required this.value,
    this.isMono = false,
    this.isLast = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF2F3ED), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: BovaraText.label(
                size: 12.5,
                color: BovaraColors.textMuted,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: BovaraText.body(
                size: 13,
                color: valueColor ?? BovaraColors.textPrimary,
              ).copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: isMono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CARD DE ESTADO REPRODUCTIVO (solo hembra en celo)
// ═════════════════════════════════════════════════════════════════

class _ReproStatusCard extends StatelessWidget {
  final HeatEventModel? latestHeat;
  final VoidCallback onRegisterHeat;
  const _ReproStatusCard({required this.latestHeat, required this.onRegisterHeat});

  String _hoursAgoText(DateTime heatDate) {
    final hours = DateTime.now().difference(heatDate).inHours;
    if (hours < 1) return 'Celo detectado hace menos de 1 h';
    if (hours < 24) return 'Celo detectado hace $hours h';
    final days = hours ~/ 24;
    return 'Celo detectado hace $days ${days == 1 ? 'día' : 'días'}';
  }

  String _windowText(DateTime heatDate) {
    final elapsedHours = DateTime.now().difference(heatDate).inHours;
    final remaining = 12 - elapsedHours;
    if (remaining <= 0) {
      return 'Ventana de 12 h desde el celo ya pasó — evalúa si sigue en pie.';
    }
    return 'Próximas $remaining h desde que se detectó el celo.';
  }

  @override
  Widget build(BuildContext context) {
    final heat = latestHeat;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF6D9E6), width: 1.5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 8),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: BovaraColors.celoSoftBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.favorite_rounded,
                    size: 17, color: BovaraColors.celo),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado reproductivo',
                        style: BovaraText.heading()
                            .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Text(
                      heat != null ? _hoursAgoText(heat.heatDate) : 'Sin celo reciente registrado',
                      style: BovaraText.label(
                        size: 12,
                        color: const Color(0xFFC4548A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (heat != null) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF3F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ventana de inseminación',
                      style: BovaraText.label(size: 12.5, color: const Color(0xFFB03A6B))),
                  const SizedBox(height: 2),
                  Text(_windowText(heat.heatDate),
                      style: BovaraText.body(size: 13.5, color: BovaraColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (heat.probability != null) ...[
                    const SizedBox(height: 2),
                    Text('Análisis: ${heat.probability}%',
                        style: BovaraText.label(size: 12, color: BovaraColors.textMuted)),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRegisterHeat,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(-0.3, -1),
                    end: Alignment(0.5, 1),
                    colors: [Color(0xFFE0559B), BovaraColors.celo],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: BovaraColors.celo.withValues(alpha: 0.6),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Registrar celo',
                    style: BovaraText.label(size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// GRÁFICO DE PESO (mock)
// ═════════════════════════════════════════════════════════════════

// ═════════════════════════════════════════════════════════════════
// FORMULARIO DE REGISTRO DE PARTO (bottom sheet)
// ═════════════════════════════════════════════════════════════════

class _BirthFormResult {
  final DateTime birthDate;
  final bool registerCalf;
  final String? calfName;
  final String? calfLote;
  final String? calfGender;
  const _BirthFormResult({
    required this.birthDate,
    required this.registerCalf,
    this.calfName,
    this.calfLote,
    this.calfGender,
  });
}

class _BirthForm extends StatefulWidget {
  final String motherLote;
  const _BirthForm({required this.motherLote});

  @override
  State<_BirthForm> createState() => _BirthFormState();
}

class _BirthFormState extends State<_BirthForm> {
  DateTime _birthDate = DateTime.now();
  bool _registerCalf = false;
  final _calfNameCtrl = TextEditingController();
  late final TextEditingController _calfLoteCtrl =
      TextEditingController(text: widget.motherLote);
  String _calfGender = 'female';

  @override
  void dispose() {
    _calfNameCtrl.dispose();
    _calfLoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar parto',
                style: BovaraText.heading().copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text('Fecha del parto',
                style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  border: Border.all(color: BovaraColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_birthDate.day.toString().padLeft(2, '0')}/${_birthDate.month.toString().padLeft(2, '0')}/${_birthDate.year}',
                        style: BovaraText.body(size: 14, color: BovaraColors.textPrimary),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 16, color: BovaraColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _registerCalf,
              onChanged: (v) => setState(() => _registerCalf = v),
              activeColor: BovaraColors.primary,
              title: Text('¿La cría también es tuya?',
                  style: BovaraText.body(size: 14).copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text('La registramos ligada a esta madre',
                  style: BovaraText.label(size: 12, color: BovaraColors.textMuted)),
            ),
            if (_registerCalf) ...[
              const SizedBox(height: 4),
              Text('Nombre de la cría',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: _calfNameCtrl,
                decoration: InputDecoration(
                  hintText: 'Ej: Estrella',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: BovaraColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
              ),
              const SizedBox(height: 14),
              Text('Lote de la cría',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: _calfLoteCtrl,
                decoration: InputDecoration(
                  hintText: 'Ej: 406',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: BovaraColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
              ),
              const SizedBox(height: 14),
              Text('Sexo de la cría',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Hembra'),
                      selected: _calfGender == 'female',
                      onSelected: (_) => setState(() => _calfGender = 'female'),
                      selectedColor: BovaraColors.primarySoftBg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Macho'),
                      selected: _calfGender == 'male',
                      onSelected: (_) => setState(() => _calfGender = 'male'),
                      selectedColor: BovaraColors.primarySoftBg,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Guardar',
              onPressed: () {
                if (_registerCalf &&
                    (_calfNameCtrl.text.trim().isEmpty || _calfLoteCtrl.text.trim().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Falta el nombre o el lote de la cría')),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  _BirthFormResult(
                    birthDate: _birthDate,
                    registerCalf: _registerCalf,
                    calfName: _registerCalf ? _calfNameCtrl.text.trim() : null,
                    calfLote: _registerCalf ? _calfLoteCtrl.text.trim() : null,
                    calfGender: _registerCalf ? _calfGender : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HISTORIAL DE EVENTOS (real: vacunas + celo, mezclados por fecha)
// ═════════════════════════════════════════════════════════════════

class _EventsHistoryCard extends StatefulWidget {
  final String cattleId;
  const _EventsHistoryCard({required this.cattleId});

  @override
  State<_EventsHistoryCard> createState() => _EventsHistoryCardState();
}

class _EventsHistoryCardState extends State<_EventsHistoryCard> {
  final _healthService = HealthEventService();
  final _heatService = HeatEventService();
  bool _loading = true;
  List<_Event> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _healthService.getHealthEventsByCattle(widget.cattleId),
        _heatService.getHeatEventsByCattle(widget.cattleId),
      ]);
      final health = results[0] as List<HealthEventModel>;
      final heat = results[1] as List<HeatEventModel>;

      final events = <_Event>[
        for (final h in health)
          _Event(
            title: h.eventTypeSpanish == 'Vacuna'
                ? 'Vacuna${h.medicineName != null ? ': ${h.medicineName}' : ''}'
                : h.eventTypeSpanish,
            when: h.formattedDate,
            meta: () {
              final parts = [
                if (h.veterinarianName != null) 'Aplicada por ${h.veterinarianName}',
                if (h.dosage != null) 'Dosis: ${h.dosage}',
                if (h.notes != null) h.notes!,
              ];
              return parts.isEmpty ? 'Sin notas adicionales' : parts.join(' · ');
            }(),
            color: BovaraColors.info,
            ring: BovaraColors.infoSoftBg,
            date: h.applicationDate,
          ),
        for (final ev in heat)
          _Event(
            title: ev.wasInseminated ? 'Celo (inseminada)' : 'Celo detectado',
            when: ev.formattedHeatDate,
            meta: [
              if (ev.probability != null) 'Análisis: ${ev.probability}%',
              ev.comportamiento,
            ].join(' · '),
            color: BovaraColors.celo,
            ring: BovaraColors.celoSoftBg,
            date: ev.heatDate,
          ),
      ];
      events.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial de eventos',
              style: BovaraText.heading()
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: BovaraColors.primary, strokeWidth: 2.4),
              ),
            )
          else if (_events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Todavía no hay vacunas ni eventos de celo registrados para este animal.',
                style: BovaraText.label(size: 13, color: BovaraColors.textMuted),
              ),
            )
          else
            for (var i = 0; i < _events.length; i++)
              _EventRow(
                event: _events[i],
                isLast: i == _events.length - 1,
              ),
        ],
      ),
    );
  }
}

class _Event {
  final String title;
  final String when;
  final String meta;
  final Color color;
  final Color ring;
  final DateTime date;
  const _Event({
    required this.title,
    required this.when,
    required this.meta,
    required this.color,
    required this.ring,
    required this.date,
  });
}

class _EventRow extends StatelessWidget {
  final _Event event;
  final bool isLast;
  const _EventRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: event.ring, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFEEF0EA)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(event.title,
                            style: BovaraText.body(
                              size: 13.5,
                              color: BovaraColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        event.when,
                        style: BovaraText.label(size: 11, color: BovaraColors.textDisabled),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.meta,
                    style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Contenedor blanco reutilizable
// ═════════════════════════════════════════════════════════════════

// Fila de acciones rápidas (vacuna + parto si hembra; celo vive en su
// propia card de Estado reproductivo, ya no aquí duplicado)
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onVaccine;
  final bool isFemale;
  final VoidCallback onBirth;

  const _QuickActionsRow({
    required this.onVaccine,
    required this.isFemale,
    required this.onBirth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.medical_services_outlined,
            label: 'Registrar\nvacuna',
            colors: const [Color(0xFF4C82EE), Color(0xFF2456C7)],
            onTap: onVaccine,
          ),
        ),
        if (isFemale) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionBtn(
              icon: Icons.child_friendly_outlined,
              label: 'Registrar\nparto',
              colors: const [Color(0xFFD4A24C), Color(0xFFB8862E)],
              onTap: onBirth,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.3, -1),
              end: const Alignment(0.5, 1),
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.5),
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: BovaraText.label(size: 13, color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w800, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 8),
            spreadRadius: -14,
          ),
        ],
      ),
      child: child,
    );
  }
}
