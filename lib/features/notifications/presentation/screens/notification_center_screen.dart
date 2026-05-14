import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/notification_card.dart';
import '../../../../services/notification/notification_provider.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  void _markAllAsRead() {
    context.read<NotificationProvider>().markAllAsRead();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_rounded, size: 20, color: Colors.white),
            ),
          ),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.white),
              label: Text('Mark all read', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600))),
            ListTile(
              leading: const Icon(Icons.inbox_rounded),
              title: const Text('All'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.markunread_rounded),
              title: const Text('Unread'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All Notifications', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text('${notifications.length} notifications', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_rounded, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                          const SizedBox(height: 20),
                          Text('No notifications', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          const SizedBox(height: 8),
                          Text("You're all caught up!", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return NotificationCard(
                          notification: notification,
                          onTap: () {
                            if (!notification.isRead) {
                              context.read<NotificationProvider>().markAsRead(notification.id);
                            }
                          },
                          onDismiss: () {
                            context.read<NotificationProvider>().removeNotification(notification.id);
                            _showSnackBar('Notification removed');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
