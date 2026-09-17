import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A notification lives at users/{uid}/notifications/{id}. Firestore can't
/// store an IconData directly, so `iconKey` is a short string identifier
/// mapped back to a real icon via [icon] below — add new keys here as new
/// notification types are introduced elsewhere in the app.
class NotificationModel {
  final String id;
  final String iconKey;
  final String title;
  final String subtitle;
  final bool unread;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.iconKey,
    required this.title,
    required this.subtitle,
    required this.unread,
    required this.createdAt,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NotificationModel(
      id: doc.id,
      iconKey: data['iconKey'] ?? 'market',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      unread: data['unread'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  IconData get icon {
    switch (iconKey) {
      case 'booking':
        return Icons.event_available_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'market':
      default:
        return Icons.campaign_rounded;
    }
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
