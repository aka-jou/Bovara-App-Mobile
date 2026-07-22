// lib/features/cattle/presentation/pages/cattle_list_page.dart
//
// Lista de ganado (Grupo E · Lista del rediseño).
//
// Estructura:
//   - Header con título "Mi hato" + subtítulo con conteos reales.
//   - Search bar y chips de filtro por lote (Todos | Lote A | Lote B | …).
//   - Lista de cards con avatar circular, arete + nombre, meta (lote · peso · edad)
//     y badge de estado (En celo / Al día / Pendiente).
//   - FAB "Nueva vaca" flotante con gradient verde.
//
// LÓGICA: usa CattleService.getCattleList() para datos reales; los badges
// se calculan localmente hasta que haya una fuente de verdad de estado
// reproductivo/salud por animal.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/cattle_model.dart';
import '../../data/services/cattle_service.dart';

class CattleListPage extends StatefulWidget {
  const CattleListPage({super.key});

  @override
  State<CattleListPage> createState() => _CattleListPageState();
}

class _CattleListPageState extends State<CattleListPage> {
  final _service = CattleService();
  final _searchCtrl = TextEditingController();

  List<CattleModel> _all = [];
  bool _loading = true;
  String? _error;
  String _selectedFilter = 'Todos';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getCattleList();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No pude cargar el hato. Revisa tu conexión.';
        _loading = false;
      });
    }
  }

  List<String> get _availableFilters {
    final lotes = _all.map((c) => c.lote).toSet().toList()..sort();
    return ['Todos', ...lotes];
  }

  List<CattleModel> get _filtered {
    Iterable<CattleModel> res = _all;
    if (_selectedFilter != 'Todos') {
      res = res.where((c) => c.lote == _selectedFilter);
    }
    if (_query.isNotEmpty) {
      res = res.where((c) {
        return c.name.toLowerCase().contains(_query) ||
            c.lote.toLowerCase().contains(_query) ||
            c.id.toLowerCase().contains(_query);
      });
    }
    return res.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  total: _all.length,
                  loteCount: _availableFilters.length - 1,
                  onBack: () => context.go('/home'),
                ),
                _SearchBar(controller: _searchCtrl),
                _FilterChips(
                  filters: _availableFilters,
                  selected: _selectedFilter,
                  onSelect: (f) => setState(() => _selectedFilter = f),
                ),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 26 + MediaQuery.of(context).padding.bottom,
              child: _NewCattleFab(onTap: () async {
                await context.push('/cattle/new');
                if (mounted) _load();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: BovaraColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: BovaraColors.textMuted),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: BovaraText.body(size: 14, color: BovaraColors.textSecondary)),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _load,
                child: Text('Reintentar',
                    style: BovaraText.label(size: 13, color: BovaraColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            _all.isEmpty
                ? 'Aún no hay animales registrados.\nToca "Nueva vaca" para empezar.'
                : 'No se encontraron animales con estos filtros.',
            textAlign: TextAlign.center,
            style: BovaraText.body(size: 14, color: BovaraColors.textMuted),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: BovaraColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 120),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, i) => _CattleCard(
          cattle: items[i],
          onTap: () => context.push('/cattle/${items[i].id}', extra: items[i]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int total;
  final int loteCount;
  final VoidCallback onBack;

  const _Header({
    required this.total,
    required this.loteCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BovaraRadius.sm),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(BovaraRadius.sm),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: BovaraColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(BovaraRadius.sm),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: BovaraColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi hato',
                  style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.23,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total ${total == 1 ? 'animal' : 'animales'}'
                  '${loteCount > 0 ? ' · $loteCount ${loteCount == 1 ? 'lote' : 'lotes'}' : ''}',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted),
                ),
              ],
            ),
          ),
          // Menú lines (placeholder)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, size: 20, color: BovaraColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BovaraRadius.md),
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
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, size: 18, color: BovaraColors.textMuted),
            const SizedBox(width: 11),
            Expanded(
              child: TextField(
                controller: controller,
                style: BovaraText.body(size: 14, color: BovaraColors.textPrimary),
                cursorColor: BovaraColors.primary,
                decoration: InputDecoration(
                  hintText: 'Buscar por arete, nombre o lote…',
                  hintStyle: BovaraText.body(size: 14, color: BovaraColors.textDisabled),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FILTER CHIPS
// ═════════════════════════════════════════════════════════════════

class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSel = f == selected;
          return InkWell(
            onTap: () => onSelect(f),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSel ? BovaraColors.darkBar : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSel
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                          spreadRadius: -5,
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  f,
                  style: BovaraText.label(
                    size: 12.5,
                    color: isSel ? Colors.white : BovaraColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CARD DE VACA
// ═════════════════════════════════════════════════════════════════

class _CattleCard extends StatelessWidget {
  final CattleModel cattle;
  final VoidCallback onTap;

  const _CattleCard({required this.cattle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(cattle);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 6),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            children: [
              _CattleAvatar(cattle: cattle),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '#${_shortId(cattle.id)}',
                          style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            cattle.name,
                            style: BovaraText.body(size: 13, color: BovaraColors.textSecondary)
                                .copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _metaFor(cattle),
                      style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusBadge(status: status),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right,
                      size: 18, color: BovaraColors.textDisabled),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortId(String id) {
    // Muestra los primeros 3 chars del UUID para tener un "arete corto"
    return id.replaceAll('-', '').substring(0, 3).toUpperCase();
  }

  String _metaFor(CattleModel c) {
    final parts = <String>[c.lote];
    if (c.weight != null) parts.add('${c.weight!.toStringAsFixed(0)} kg');
    if (c.age != null) parts.add('${c.age} ${c.age == 1 ? 'año' : 'años'}');
    return parts.join(' · ');
  }

  _CattleStatus _statusFor(CattleModel c) {
    // Placeholder: sin campo de estado en el modelo aún.
    // Cuando integremos el ml-service para clustering se conecta aquí.
    if (c.clusterLabel == 'Alta Atención Médica') return _CattleStatus.pending;
    if (c.clusterLabel == 'Ganado en Tratamiento') return _CattleStatus.pending;
    return _CattleStatus.ok;
  }
}

// Avatar circular con inicial. En el futuro, si se agrega URL de foto,
// aquí se pone Image.network con fallback.
class _CattleAvatar extends StatelessWidget {
  final CattleModel cattle;
  const _CattleAvatar({required this.cattle});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = cattle.photoUrl != null && cattle.photoUrl!.isNotEmpty;
    final initial = cattle.name.isNotEmpty ? cattle.name[0].toUpperCase() : '?';

    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          cattle.photoUrl!,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _InitialFallback(initial: initial),
          errorBuilder: (_, __, ___) => _InitialFallback(initial: initial),
        ),
      );
    }
    return _InitialFallback(initial: initial);
  }
}

class _InitialFallback extends StatelessWidget {
  final String initial;
  const _InitialFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.3, -1),
          end: Alignment(0.7, 1),
          colors: [Color(0xFFD7A883), Color(0xFFB58453)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: BovaraText.title(color: Colors.white).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

enum _CattleStatus { ok, celo, pending }

class _StatusBadge extends StatelessWidget {
  final _CattleStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      _CattleStatus.ok => (
        BovaraColors.primarySoftBg,
        BovaraColors.primarySoftText,
        'Al día',
      ),
      _CattleStatus.celo => (
        BovaraColors.celoSoftBg,
        BovaraColors.celo,
        'En celo',
      ),
      _CattleStatus.pending => (
        BovaraColors.warningSoftBg,
        const Color(0xFFA86A1E),
        'Pendiente',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: BovaraText.label(size: 10.5, color: fg).copyWith(letterSpacing: 0.2),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FAB NUEVA VACA
// ═════════════════════════════════════════════════════════════════

class _NewCattleFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NewCattleFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.3, -1),
              end: Alignment(0.5, 1),
              colors: [Color(0xFF3DA35D), BovaraColors.primary],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: BovaraColors.primary.withValues(alpha: 0.75),
                blurRadius: 30,
                offset: const Offset(0, 14),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 9),
              Text(
                'Nueva vaca',
                style: BovaraText.label(size: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
