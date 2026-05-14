import 'package:flutter/material.dart';

/// Represents a route entry in the navigation stack
class RouteEntry {
  final String routeName;
  final int tabIndex;
  final Object? arguments;
  final DateTime timestamp;

  RouteEntry({
    required this.routeName,
    required this.tabIndex,
    this.arguments,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RouteEntry(route: $routeName, tab: $tabIndex, time: $timestamp)';
  }
}

/// Manages a global navigation stack across all tabs
class NavigationStackManager {
  static final NavigationStackManager _instance = NavigationStackManager._internal();
  factory NavigationStackManager() => _instance;
  NavigationStackManager._internal();

  /// Get the singleton instance
  static NavigationStackManager get instance => _instance;

  final List<RouteEntry> _stack = [];
  int _currentTabIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [];

  /// Get the current navigation stack (read-only copy)
  List<RouteEntry> get stack => List.unmodifiable(_stack);

  /// Get the current tab index
  int get currentTabIndex => _currentTabIndex;

  /// Get the current route (top of stack)
  RouteEntry? get currentRoute => _stack.isNotEmpty ? _stack.last : null;

  /// Set the current tab index (called when tab changes)
  set currentTabIndex(int index) {
    _currentTabIndex = index;
  }

  /// Set the navigator keys from MainNavigationShell
  static void setNavigatorKeys(List<GlobalKey<NavigatorState>> keys) {
    instance._navigatorKeys.clear();
    instance._navigatorKeys.addAll(keys);
  }

  /// Get the current navigator keys (for observer)
  static List<GlobalKey<NavigatorState>> get navigatorKeys => instance._navigatorKeys;

  /// Get the navigator key for a given tab index
  GlobalKey<NavigatorState>? _getNavigatorKeyForTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _navigatorKeys.length) {
      return _navigatorKeys[tabIndex];
    }
    return null;
  }

  /// Push a new route onto the stack
  void pushRoute(String routeName, {required int tabIndex, Object? arguments}) {
    _stack.add(RouteEntry(
      routeName: routeName,
      tabIndex: tabIndex,
      arguments: arguments,
      timestamp: DateTime.now(),
    ));
  }

  /// Remove the current route from stack (when a route is popped)
  void popRoute() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
  }

  /// Pop until a specific tab is at the top
  void popToTab(int tabIndex) {
    while (_stack.isNotEmpty && _stack.last.tabIndex != tabIndex) {
      popRoute();
    }
  }

  /// Clear the entire stack and set a new root (Dashboard)
  void resetToDashboard() {
    _stack.clear();
    _stack.add(RouteEntry(
      routeName: '/dashboard',
      tabIndex: 0,
      timestamp: DateTime.now(),
    ));
    _currentTabIndex = 0;
  }

  /// Check if we can pop (more than one route in stack)
  bool canPop() {
    return _stack.length > 1;
  }

  /// Get total number of routes in stack
  int get depth => _stack.length;

  /// Get the route at specific index (0 = root/Dashboard)
  RouteEntry? getRouteAt(int index) {
    if (index < 0 || index >= _stack.length) return null;
    return _stack[index];
  }
}
