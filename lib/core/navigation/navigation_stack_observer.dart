import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show PopupRoute;
import 'navigation_stack_manager.dart';
import 'navigation_service.dart';

/// NavigatorObserver that automatically tracks route changes and updates the global stack
class NavigationStackObserver extends NavigatorObserver {
  /// Helper to determine if route should be tracked
  bool _shouldTrack(Route route) {
    // Ignore initial routes and popup routes (dialogs, menus)
    return !route.isFirst && route is! PopupRoute;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      if (!_shouldTrack(route)) return;

      final navigator = route.navigator;
      if (navigator == null) return;

      final tabIndex = _getTabIndexForNavigator(navigator);
      final routeName = route.settings.name ?? route.runtimeType.toString();

      NavigationStackManager.instance.pushRoute(
        routeName,
        tabIndex: tabIndex,
        arguments: route.settings.arguments,
      );
    } catch (e) {
      // Ignore errors in observer to prevent crashes
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      if (!_shouldTrack(route)) return;

      NavigationStackManager.instance.popRoute();

      // After pop, check if we need to switch tabs
      final stackManager = NavigationStackManager.instance;
      final newCurrent = stackManager.currentRoute;
      if (newCurrent != null) {
        final targetTab = newCurrent.tabIndex;
        if (targetTab != stackManager.currentTabIndex) {
          stackManager.currentTabIndex = targetTab;
          currentTabIndex.value = targetTab;
        }
      }
    } catch (e) {
      // Ignore errors in observer to prevent crashes
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    try {
      if (!_shouldTrack(route)) return;
      NavigationStackManager.instance.popRoute();

      final stackManager = NavigationStackManager.instance;
      final newCurrent = stackManager.currentRoute;
      if (newCurrent != null) {
        final targetTab = newCurrent.tabIndex;
        if (targetTab != stackManager.currentTabIndex) {
          stackManager.currentTabIndex = targetTab;
          currentTabIndex.value = targetTab;
        }
      }
    } catch (e) {
      // Ignore errors in observer to prevent crashes
    }
  }

  @override
  void didReplace({Route? oldRoute, Route? newRoute}) {
    super.didReplace(oldRoute: oldRoute, newRoute: newRoute);
    try {
      final stackManager = NavigationStackManager.instance;

      if (oldRoute != null && !oldRoute.isFirst) {
        stackManager.popRoute();
      }

      if (newRoute != null && _shouldTrack(newRoute)) {
        final navigator = newRoute.navigator;
        if (navigator != null) {
          final tabIndex = _getTabIndexForNavigator(navigator);
          final routeName = newRoute.settings.name ?? newRoute.runtimeType.toString();
          stackManager.pushRoute(
            routeName,
            tabIndex: tabIndex,
            arguments: newRoute.settings.arguments,
          );
        }
      }

      // After replacement, check if tab switch needed
      final newCurrent = stackManager.currentRoute;
      if (newCurrent != null) {
        final targetTab = newCurrent.tabIndex;
        if (targetTab != stackManager.currentTabIndex) {
          stackManager.currentTabIndex = targetTab;
          currentTabIndex.value = targetTab;
        }
      }
    } catch (e) {
      // Ignore errors in observer to prevent crashes
    }
  }

  /// Determine the tab index associated with this navigator
  int _getTabIndexForNavigator(NavigatorState navigator) {
    try {
      final keys = NavigationStackManager.navigatorKeys;
      for (int i = 0; i < keys.length; i++) {
        if (keys[i].currentState == navigator) {
          return i;
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return NavigationStackManager.instance.currentTabIndex;
  }
}
