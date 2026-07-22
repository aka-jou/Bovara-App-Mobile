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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/cattle_model.dart';
import '../../data/services/cattle_service.dart';

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
  CattleModel? _cattle;
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
      if (!mounted) return;
      setState(() {
        _cattle = fresh;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
          SliverToBoxAdapter(child: _Header(cattle: cattle)),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    _HeroCard(cattle: cattle),
                    const SizedBox(height: 14),
                    _AnimalSheet(cattle: cattle),
                    const SizedBox(height: 14),
                    _QuickActionsRow(
                      onVaccine: () =>
                          context.push('/cattle/${cattle.id}/vaccine', extra: cattle),
                      isFemale: cattle.gender.toLowerCase() == 'female',
                      onHeat: () =>
                          context.push('/cattle/${cattle.id}/zeal', extra: cattle),
                    ),
                    if (cattle.gender.toLowerCase() == 'female') ...[
                      const SizedBox(height: 14),
                      _ReproStatusCard(
                        onRegisterHeat: () =>
                            context.push('/cattle/${cattle.id}/zeal', extra: cattle),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _WeightChartCard(cattle: cattle),
                    const SizedBox(height: 14),
                    const _EventsHistoryCard(),
                    const SizedBox(height: 40),
                  ],
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
// HEADER VERDE
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final CattleModel cattle;
  const _Header({required this.cattle});

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
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 60),
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
                      'Vaca #${_shortId(cattle.id)}',
                      style: BovaraText.title(color: Colors.white).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${cattle.name} · ${cattle.lote}',
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Editar disponible próximamente')),
                    );
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

  String _shortId(String id) =>
      id.replaceAll('-', '').substring(0, 3).toUpperCase();
}

// ═════════════════════════════════════════════════════════════════
// HERO CARD (foto + chips + stats)
// ═════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final CattleModel cattle;
  const _HeroCard({required this.cattle});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (cattle.gender.toLowerCase() == 'female')
        _MiniChip(
          label: 'En celo · 94%',
          bg: BovaraColors.celoSoftBg,
          fg: BovaraColors.celoSoftText,
        ),
      _MiniChip(
        label: cattle.breed,
        bg: BovaraColors.surfaceAlt,
        fg: BovaraColors.textPrimary,
      ),
      _MiniChip(
        label: cattle.gender.toLowerCase() == 'female' ? 'Hembra' : 'Macho',
        bg: BovaraColors.surfaceAlt,
        fg: BovaraColors.textPrimary,
      ),
    ];

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
          // Slot de foto — muestra la foto real de Cloudinary si existe
          Container(
            height: 168,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: BovaraColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BovaraColors.border, width: 1),
            ),
            child: cattle.photoUrl != null && cattle.photoUrl!.isNotEmpty
                ? Image.network(
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
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 28, color: BovaraColors.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        'Sin foto',
                        style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: chips,
                ),
              ),
              _SyncIndicator(),
            ],
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
                  value: cattle.fechaUltimoParto != null ? '1' : '0',
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

class _MiniChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _MiniChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(
        label,
        style: BovaraText.label(size: 11, color: fg),
      ),
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: BovaraColors.warning,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text('Pend. subir',
            style: BovaraText.label(size: 10.5, color: const Color(0xFFA8863C))),
      ],
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
            label: 'Arete oficial',
            value: cattle.tag,
            isMono: true,
          ),
          _SheetRow(
            label: 'Nombre',
            value: cattle.name,
          ),
          _SheetRow(
            label: 'Nacimiento',
            value: cattle.birthDate != null
                ? '${cattle.formattedBirthDate} · ${cattle.age} ${cattle.age == 1 ? 'año' : 'años'}'
                : 'Sin registro',
          ),
          if (cattle.fechaUltimoParto != null)
            _SheetRow(
              label: 'Último parto',
              value: cattle.formattedLastBirth,
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
  final VoidCallback onRegisterHeat;
  const _ReproStatusCard({required this.onRegisterHeat});

  @override
  Widget build(BuildContext context) {
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
                    Text('Celo detectado hace 6 h',
                        style: BovaraText.label(
                          size: 12,
                          color: const Color(0xFFC4548A),
                        )),
                  ],
                ),
              ),
            ],
          ),
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
                Text('Próximas 12 horas · óptimo antes de las 8:00 PM',
                    style: BovaraText.body(size: 13.5, color: BovaraColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
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
                    'Registrar inseminación',
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

class _WeightChartCard extends StatelessWidget {
  final CattleModel cattle;
  const _WeightChartCard({required this.cattle});

  @override
  Widget build(BuildContext context) {
    // Datos de muestra hasta que exista un endpoint de series de peso
    final data = <_WPoint>[
      _WPoint(mes: 'ene', kg: 432, isCurrent: false),
      _WPoint(mes: 'feb', kg: 438, isCurrent: false),
      _WPoint(mes: 'mar', kg: 442, isCurrent: false),
      _WPoint(mes: 'abr', kg: 445, isCurrent: false),
      _WPoint(mes: 'may', kg: 448, isCurrent: false),
      _WPoint(mes: 'jun', kg: (cattle.weight ?? 450).toInt(), isCurrent: true),
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text('Evolución de peso',
                    style: BovaraText.heading()
                        .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Text(
                '+18 kg en 6 meses',
                style: BovaraText.label(size: 12, color: BovaraColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: _WeightBars(data: data),
          ),
        ],
      ),
    );
  }
}

class _WPoint {
  final String mes;
  final int kg;
  final bool isCurrent;
  const _WPoint({required this.mes, required this.kg, required this.isCurrent});
}

class _WeightBars extends StatelessWidget {
  final List<_WPoint> data;
  const _WeightBars({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxKg = data.map((p) => p.kg).reduce((a, b) => a > b ? a : b);
    final minKg = data.map((p) => p.kg).reduce((a, b) => a < b ? a : b);
    final range = (maxKg - minKg).clamp(1, 999);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((p) {
        final ratio = (p.kg - minKg) / range;
        final height = 30 + ratio * 60; // 30-90 px
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${p.kg}',
                  style: BovaraText.label(
                    size: 10,
                    color: p.isCurrent ? BovaraColors.primary : BovaraColors.textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  height: height,
                  decoration: BoxDecoration(
                    color: p.isCurrent
                        ? BovaraColors.primary
                        : const Color(0xFFC4E2CA),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  p.mes,
                  style: BovaraText.label(size: 10, color: BovaraColors.textMuted),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HISTORIAL DE EVENTOS (mock timeline)
// ═════════════════════════════════════════════════════════════════

class _EventsHistoryCard extends StatelessWidget {
  const _EventsHistoryCard();

  @override
  Widget build(BuildContext context) {
    // Placeholder mientras no haya un endpoint unificado de eventos.
    // Cuando conectemos HealthEventService + HeatEventService aquí se
    // arma la timeline real.
    final events = <_Event>[
      _Event(
        title: 'Celo detectado',
        when: 'Hoy · 8:12 AM',
        meta: 'Signos: monta natural, secreción · ventana 12 h',
        color: BovaraColors.celo,
        ring: BovaraColors.celoSoftBg,
      ),
      _Event(
        title: 'Vacunación anti-mastitis',
        when: 'Hace 12 días',
        meta: 'Aplicada por Dr. Ramírez · próxima en 6 meses',
        color: BovaraColors.info,
        ring: BovaraColors.infoSoftBg,
      ),
      _Event(
        title: 'Pesaje mensual',
        when: 'Hace 22 días',
        meta: '432 kg → 450 kg (+18 kg)',
        color: BovaraColors.primary,
        ring: BovaraColors.primarySoftBg,
      ),
      _Event(
        title: 'Parto natural',
        when: '10 ene 2026',
        meta: 'Cría #501 (hembra) · 38 kg al nacer',
        color: const Color(0xFFB8862E),
        ring: BovaraColors.warningSoftBg,
      ),
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Historial de eventos',
                    style: BovaraText.heading()
                        .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Text('Ver todo',
                  style: BovaraText.label(size: 12, color: BovaraColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < events.length; i++)
            _EventRow(
              event: events[i],
              isLast: i == events.length - 1,
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
  const _Event({
    required this.title,
    required this.when,
    required this.meta,
    required this.color,
    required this.ring,
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

// Fila de acciones rápidas (vacuna + celo si hembra)
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onVaccine;
  final bool isFemale;
  final VoidCallback onHeat;

  const _QuickActionsRow({
    required this.onVaccine,
    required this.isFemale,
    required this.onHeat,
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
              icon: Icons.favorite_rounded,
              label: 'Registrar\ncelo',
              colors: const [Color(0xFFE0559B), BovaraColors.celo],
              onTap: onHeat,
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
