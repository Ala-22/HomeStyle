import 'package:flutter/material.dart';

import '../services/notification_center.dart';

IconData _iconFor(String key) {
  switch (key) {
    case 'celebration':
      return Icons.celebration_rounded;
    case 'auto_awesome':
      return Icons.auto_awesome_rounded;
    case 'local_offer':
      return Icons.local_offer_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'shopping_cart':
      return Icons.shopping_cart_rounded;
    case 'new':
      return Icons.fiber_new_rounded;
    case 'check_circle':
      return Icons.check_circle_rounded;
    case 'design':
      return Icons.design_services_rounded;
    case 'delete':
      return Icons.delete_forever_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

const _palette = [
  Color(0xFF5D4037),
  Color(0xFF1565C0),
  Color(0xFFEF6C00),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFFC62828),
];

Color _colorFor(int index) {
  return _palette[index.clamp(0, _palette.length - 1)];
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return '${date.day}/${date.month}/${date.year}';
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _openNotification(BuildContext context, AppNotification notification) {
    NotificationCenter.instance.markRead(notification.id);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          _iconFor(notification.icon),
          color: _colorFor(notification.colorIndex),
          size: 40,
        ),
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 12),
            Text(
              _timeAgo(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ListenableBuilder(
            listenable: NotificationCenter.instance,
            builder: (context, _) {
              final center = NotificationCenter.instance;

              return IconButton(
                tooltip: 'Mark all as read',
                onPressed: center.unreadCount == 0
                    ? null
                    : () async {
                        await center.markAllRead();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('All notifications marked as read'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.done_all_rounded),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: NotificationCenter.instance,
        builder: (context, _) {
          final items = NotificationCenter.instance.items;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 70,
                    color: Colors.brown,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Things that happen in the app will show up here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = items[index];
              final color = _colorFor(n.colorIndex);

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: n.read
                      ? BorderSide.none
                      : BorderSide(color: color, width: 1.2),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(_iconFor(n.icon), color: color),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: n.read ? null : color,
                          ),
                        ),
                      ),
                      if (!n.read) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    n.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    _timeAgo(n.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  onTap: () => _openNotification(context, n),
                ),
              );
            },
          );
        },
      ),
    );
  }
}