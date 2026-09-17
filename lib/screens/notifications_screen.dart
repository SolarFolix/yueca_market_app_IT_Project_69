import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class _NotificationItem {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  bool unread;
  _NotificationItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
  });

  factory _NotificationItem.fromModel(NotificationModel m) => _NotificationItem(
        id: m.id,
        icon: m.icon,
        title: m.title,
        subtitle: m.subtitle,
        time: m.relativeTime,
        unread: m.unread,
      );
}

/// Mock data — the starting state for guest/offline mode only. When
/// Firebase is configured, initState below subscribes to the real
/// notification inbox instead and this seed is never used.
List<_NotificationItem> _seedNotifications() => [
      _NotificationItem(
        id: '1',
        icon: Icons.event_available_rounded,
        title: 'Booking confirmed',
        subtitle: 'Your slot A2 for 29 Jul is confirmed.',
        time: '2h ago',
        unread: true,
      ),
      _NotificationItem(
        id: '2',
        icon: Icons.payments_rounded,
        title: 'Payment received',
        subtitle: '฿250 slot fee received for Store 1.',
        time: '5h ago',
        unread: true,
      ),
      _NotificationItem(
        id: '3',
        icon: Icons.campaign_rounded,
        title: 'Market update',
        subtitle: 'Zone C will be closed for maintenance on Friday.',
        time: 'Yesterday',
        unread: false,
      ),
      _NotificationItem(
        id: '4',
        icon: Icons.star_rounded,
        title: 'New review',
        subtitle: 'Someone left a 5-star review on Fresh Produce.',
        time: '2 days ago',
        unread: false,
      ),
    ];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_NotificationItem> _items = AuthService.instance.isAvailable ? [] : _seedNotifications();
  StreamSubscription<List<NotificationModel>>? _sub;

  bool get _isBackedByFirestore => AuthService.instance.isAvailable;

  @override
  void initState() {
    super.initState();
    if (_isBackedByFirestore) {
      _sub = NotificationService.instance.watchNotifications().listen((models) {
        if (!mounted) return;
        setState(() => _items = models.map(_NotificationItem.fromModel).toList());
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    if (_isBackedByFirestore) {
      final ids = _items.where((n) => n.unread).map((n) => n.id).toList();
      await NotificationService.instance.markAllRead(ids);
    } else {
      setState(() {
        for (final n in _items) {
          n.unread = false;
        }
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read')));
    }
  }

  Future<void> _clearAll() async {
    if (_isBackedByFirestore) {
      final ids = _items.map((n) => n.id).toList();
      await NotificationService.instance.clearAll(ids);
    } else {
      setState(() => _items = []);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications cleared')));
    }
  }

  Future<void> _dismiss(_NotificationItem item) async {
    if (_isBackedByFirestore) {
      await NotificationService.instance.dismiss(item.id);
    } else {
      setState(() => _items.removeWhere((n) => n.id == item.id));
    }
  }

  Future<void> _markRead(_NotificationItem item) async {
    if (!item.unread) return;
    if (_isBackedByFirestore) {
      await NotificationService.instance.markRead(item.id);
    } else {
      setState(() => item.unread = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => n.unread).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
          title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          centerTitle: false,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                if (value == 'mark_all') _markAllRead();
                if (value == 'clear_all') _clearAll();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'mark_all', child: Text('Mark all as read')),
                PopupMenuItem(value: 'clear_all', child: Text('Clear all')),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Notifications'), Tab(text: 'Unread')],
          ),
        ),
        body: TabBarView(
          children: [
            _NotificationList(items: _items, onDismiss: _dismiss, onTapItem: _markRead),
            _NotificationList(items: unread, onDismiss: _dismiss, onTapItem: _markRead),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<_NotificationItem> items;
  final ValueChanged<_NotificationItem> onDismiss;
  final ValueChanged<_NotificationItem> onTapItem;
  const _NotificationList({required this.items, required this.onDismiss, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        message: 'No Notifications',
        sub: "We'll let you know when there will be something to update you.",
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _tile(context, items[i]),
    );
  }

  Widget _tile(BuildContext context, _NotificationItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => onTapItem(item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.unread ? AppColors.primary.withOpacity(0.25) : AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                        Text(item.time, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(item.subtitle, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (item.unread) ...[
                const SizedBox(width: 6),
                Container(height: 8, width: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.unread, shape: BoxShape.circle)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: AppTextStyles.subheading),
          ],
        ),
      ),
    );
  }
}
