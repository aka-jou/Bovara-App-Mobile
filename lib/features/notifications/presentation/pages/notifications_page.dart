// lib/features/notifications/presentation/pages/notifications_page.dart
//
// Notificaciones — ahora con datos REALES del backend
// (notifications-service). Una cuenta nueva ve la lista vacía hasta que
// ocurre el primer evento (recordatorio próximo a vencer, etc). Tocar un
// item marca como leído y navega a la sección correspondiente.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../data/models/notification_log_model.dart';
import '../../data/services/notification_log_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationLogService();
  List<NotificationLogModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No pude cargar tus notificaciones.';
        _loading = false;
      });
    }
  }

  int get _unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> _markAllRead() async {
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
    await _service.markAllRead();
  }

  Future<void> _onTapItem(NotificationLogModel n) async {
    if (!n.isRead) {
      setState(() {
        _items = _items.map((x) => x.id == n.id ? x.copyWith(isRead: true) : x).toList();
      });
      _service.markRead(n.id);
    }
    if (!mounted) return;
    switch (n.referenceType) {
      case 'reminder':
        context.push('/reminders');
        break;
      case 'cattle':
        if (n.referenceId != null) context.push('/cattle/${n.referenceId}');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surfaceAlt,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              unread: _unreadCount,
              onBack: () => context.go('/home'),
              onMarkAllRead: _unreadCount > 0 ? _markAllRead : null,
            ),
            Expanded(child: _buildBody()),
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
              Text(_error!, textAlign: TextAlign.center,
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
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 46, color: BovaraColors.textDisabled),
              const SizedBox(height: 14),
              Text('Sin notificaciones todavía',
                  style: BovaraText.heading(color: BovaraColors.textSecondary)),
              const SizedBox(height: 6),
              Text(
                'Aquí verás avisos de celos, vacunas y tareas\ncuando ocurran.',
                textAlign: TextAlign.center,
                style: BovaraText.label(size: 13, color: BovaraColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: BovaraColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _NotifCard(
          item: _items[i],
          onTap: () => _onTapItem(_items[i]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int unread;
  final VoidCallback onBack;
  final VoidCallback? onMarkAllRead;

  const _Header({required this.unread, required this.onBack, required this.onMarkAllRead});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: BovaraColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: BovaraColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificaciones',
                    style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(height: 1),
                Text(
                  unread == 0 ? 'Al día' : '$unread sin leer',
                  style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted),
                ),
              ],
            ),
          ),
          if (onMarkAllRead != null)
            InkWell(
              onTap: onMarkAllRead,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text('Marcar leídas',
                    style: BovaraText.label(size: 12.5, color: BovaraColors.primary)),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CARD
// ═════════════════════════════════════════════════════════════════

class _NotifCard extends StatelessWidget {
  final NotificationLogModel item;
  final VoidCallback onTap;

  const _NotifCard({required this.item, required this.onTap});

  (IconData, Color, Color) get _visual {
    switch (item.notifType) {
      case 'vaccine':
        return (Icons.medical_services_outlined, BovaraColors.info, BovaraColors.infoSoftBg);
      case 'breeding':
        return (Icons.favorite_rounded, BovaraColors.celo, BovaraColors.celoSoftBg);
      case 'checkup':
        return (Icons.health_and_safety_outlined, BovaraColors.primary, BovaraColors.primarySoftBg);
      case 'feeding':
        return (Icons.grass_outlined, BovaraColors.warning, BovaraColors.warningSoftBg);
      default:
        return (Icons.notifications_none_rounded, BovaraColors.textSecondary, BovaraColors.surfaceAlt);
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = _visual;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 6),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Stack(
            children: [
              if (!item.isRead)
                Positioned(
                  top: 2,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: BovaraColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
                    child: Icon(icon, size: 20, color: fg),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: item.isRead ? 0 : 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: BovaraText.body(size: 13.5, color: BovaraColors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(item.body,
                              style: BovaraText.body(size: 12.5, color: BovaraColors.textSecondary)
                                  .copyWith(fontWeight: FontWeight.w500, height: 1.4)),
                          const SizedBox(height: 8),
                          Text(_timeAgo(item.createdAt),
                              style: BovaraText.label(size: 10.5, color: BovaraColors.textDisabled)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
