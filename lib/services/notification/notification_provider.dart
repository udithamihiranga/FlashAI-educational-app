import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flashai/features/notifications/presentation/models/notification_model.dart';
import 'package:flashai/features/notifications/presentation/data/notification_repository.dart';

/// NotificationProvider manages the application's notification state
/// including the list of notifications, unread count, and notification
/// processing logic.
/// 
/// This provider integrates with both local notifications and push
/// notifications to maintain a unified notification state.
class NotificationProvider with ChangeNotifier {
  /// Internal list of notifications
  List<NotificationItem> _notifications = [];

  /// Flag to track loading state
  bool _isLoading = false;

  /// Get the current list of notifications
  List<NotificationItem> get notifications => _notifications;

  /// Get the loading state
  bool get isLoading => _isLoading;

  /// Get the count of unread notifications
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  /// Check if there are any notifications
  bool get hasNotifications => _notifications.isNotEmpty;

  /// Get recent notifications (last 10)
  List<NotificationItem> get recentNotifications =>
      _notifications.take(10).toList();

  /// Get unread notifications
  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Get read notifications
  List<NotificationItem> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  /// Constructor initializes the notification list
  NotificationProvider() {
    _loadNotifications();
  }

  /// Load notifications from repository
  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load from repository
      _notifications = NotificationRepository.getNotifications()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification
  /// 
  /// This method is called when a new push notification is received
  /// or a local notification is created.
  /// 
  /// Parameters:
  ///   - notification: The notification to add
  ///   - prepend: Whether to add at the beginning of the list (default: true)
  void addNotification(NotificationItem notification, {bool prepend = true}) {
    if (prepend) {
      _notifications.insert(0, notification);
    } else {
      _notifications.add(notification);
    }
    
    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }

  /// Add multiple notifications
  /// 
  /// Parameters:
  ///   - notifications: List of notifications to add
  void addNotifications(List<NotificationItem> notifications) {
    _notifications.addAll(notifications);
    
    // Remove duplicates by ID
    final seen = <String>{};
    _notifications = _notifications
        .where((notification) => seen.add(notification.id))
        .toList();
    
    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }

  /// Mark a notification as read
  /// 
  /// Parameters:
  ///   - id: The ID of the notification to mark as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Mark all notifications as unread
  void markAllAsUnread() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: false);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Remove a notification
  /// 
  /// Parameters:
  ///   - id: The ID of the notification to remove
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Remove multiple notifications
  /// 
  /// Parameters:
  ///   - ids: List of notification IDs to remove
  void removeNotifications(List<String> ids) {
    final initialLength = _notifications.length;
    _notifications.removeWhere((n) => ids.contains(n.id));
    
    if (_notifications.length != initialLength) {
      notifyListeners();
    }
  }

  /// Remove all read notifications
  void removeAllRead() {
    final initialLength = _notifications.length;
    _notifications.removeWhere((n) => n.isRead);
    
    if (_notifications.length != initialLength) {
      notifyListeners();
    }
  }

  /// Filter notifications by date range
  /// 
  /// Parameters:
  ///   - startDate: Start of date range (inclusive)
  ///   - endDate: End of date range (inclusive)
  /// 
  /// Returns:
  ///   - List<NotificationItem>: Filtered notifications
  List<NotificationItem> filterByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _notifications
        .where((n) =>
            n.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
            n.timestamp.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Get notifications by read status
  /// 
  /// Parameters:
  ///   - isRead: Whether to get read or unread notifications
  /// 
  /// Returns:
  ///   - List<NotificationItem>: Filtered notifications
  List<NotificationItem> getByReadStatus(bool isRead) {
    return _notifications.where((n) => n.isRead == isRead).toList();
  }

  /// Search notifications by keyword
  /// 
  /// Parameters:
  ///   - query: Search query string
  /// 
  /// Returns:
  ///   - List<NotificationItem>: Matching notifications
  List<NotificationItem> search(String query) {
    if (query.isEmpty) {
      return _notifications;
    }

    final lowerQuery = query.toLowerCase();
    return _notifications.where((n) {
      return n.title.toLowerCase().contains(lowerQuery) ||
          n.body.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Process an incoming push notification
  /// 
  /// This method is called when a new push notification is received
  /// and handles adding it to the list and showing a local notification.
  /// 
  /// Parameters:
  ///   - notification: The notification to process
  void processPushNotification(NotificationItem notification) {
    addNotification(notification, prepend: true);
    
    // Could trigger additional actions like:
    // - Analytics tracking
    // - Badge count update
    // - Sound/vibration
  }

  /// Refresh notifications from repository
  Future<void> refresh() async {
    await _loadNotifications();
  }

  /// Get notification statistics
  /// 
  /// Returns a map containing notification statistics.
  /// 
  /// Returns:
  ///   - Map<String, dynamic>: Statistics map
  Map<String, dynamic> getStatistics() {
    final total = _notifications.length;
    final unread = unreadCount;
    final read = total - unread;

    return {
      'total': total,
      'unread': unread,
      'read': read,
      'unreadPercentage': total > 0 ? (unread / total * 100).round() : 0,
    };
  }
}

/// Extension methods for NotificationProvider
extension NotificationProviderExtensions on NotificationProvider {
  /// Group notifications by date
  /// 
  /// Returns:
  ///   - Map<DateTime, List<NotificationItem>>: Grouped notifications
  Map<DateTime, List<NotificationItem>> groupByDate() {
    final grouped = <DateTime, List<NotificationItem>>{};
    
    for (final notification in _notifications) {
      final date = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );
      
      grouped.putIfAbsent(date, () => []).add(notification);
    }
    
    return grouped;
  }
}
