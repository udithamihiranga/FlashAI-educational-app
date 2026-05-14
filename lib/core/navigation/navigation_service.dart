import 'package:flutter/material.dart';
import 'navigation_stack_manager.dart';

 /// Centralized route names for the application
 class AppRoutes {
   // Main tab routes (root level)
   static const String dashboard = '/dashboard';
   static const String notes = '/notes';
   static const String studyHub = '/study_hub';
   static const String notifications = '/notifications';
   static const String settings = '/settings';

   // Feature routes (can be pushed from any tab)
   static const String studySession = '/study_session';
   static const String shortNotes = '/short_notes';
   static const String progressDashboard = '/progress_dashboard';
   static const String savedNotes = '/saved_notes';
   static const String flashcards = '/flashcards';
   static const String flashcardsReview = '/flashcards_review';
   static const String noteDetail = '/note_detail';
   static const String editProfile = '/edit_profile';
 }

/// NavigationService provides global navigation control for the app
/// The navigation stack is automatically tracked by [NavigationStackObserver]
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final NavigationStackManager _stackManager = NavigationStackManager();

  /// Get current BuildContext
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Get the navigation stack manager
  static NavigationStackManager get stackManager => _stackManager;

  /// Initialize the navigation stack with Dashboard as root
  static void initializeStack() {
    _stackManager.resetToDashboard();
  }

  /// Set the navigator keys (called by MainNavigationShell)
  static void setNavigatorKeys(List<GlobalKey<NavigatorState>> keys) {
    NavigationStackManager.setNavigatorKeys(keys);
  }

  /// Get the appropriate navigator for a given tab index
  static NavigatorState? _getNavigatorForTab(int tabIndex) {
    final keys = NavigationStackManager.navigatorKeys;
    if (tabIndex >= 0 && tabIndex < keys.length) {
      return keys[tabIndex].currentState;
    }
    return null;
  }

  /// Navigate to a named route on the appropriate tab's navigator
  static Future<dynamic>? pushNamed(String routeName, {Object? arguments}) {
    int tabIndex = _getTabIndexForRoute(routeName);
    return _getNavigatorForTab(tabIndex)?.pushNamed(routeName, arguments: arguments);
  }

  /// Push a custom page onto a specific tab's navigator
  /// The route is automatically tracked by NavigationStackObserver
  static Future<dynamic>? pushPage({
    required WidgetBuilder builder,
    required String routeName,
    required int tabIndex,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    final route = MaterialPageRoute(
      builder: builder,
      settings: settings != null ? RouteSettings(name: routeName, arguments: settings.arguments) : RouteSettings(name: routeName),
      fullscreenDialog: fullscreenDialog,
    );
    final navigator = _getNavigatorForTab(tabIndex);
    return navigator?.push(route);
  }

/// Pop the current route on the active tab's navigator
/// The actual stack removal is handled by NavigationStackObserver
static void pop() {
  final stackManager = _stackManager;
  if (!stackManager.canPop()) {
    return; // Nothing to pop
  }

  final currentEntry = stackManager.currentRoute;
  if (currentEntry == null) return;

  final currentTab = currentEntry.tabIndex;
  final currentNavigator = _getNavigatorForTab(currentTab);

  // Check if navigator exists before attempting any operations
  if (currentNavigator != null) {
    try {
      // Only attempt to pop if the navigator actually can pop
      if (currentNavigator.canPop()) {
        // Normal case: there is a sub-page to pop within this tab
        currentNavigator.pop();
        // The observer will remove this entry from the stack and handle tab switching if needed
      } else {
        // Navigator exists but can't pop - fall back to stack management
        // This handles cases where we're at the root of a tab navigator
        stackManager.popRoute();
        final newTop = stackManager.currentRoute;
        if (newTop != null) {
          final targetTab = newTop.tabIndex;
          if (targetTab != stackManager.currentTabIndex) {
            stackManager.currentTabIndex = targetTab;
            currentTabIndex.value = targetTab;
          }
        }
      }
    } catch (e) {
      // If popping fails due to disposed navigator or other issues, 
      // fall back to stack management to keep state consistent
      stackManager.popRoute();
      final newTop = stackManager.currentRoute;
      if (newTop != null) {
        final targetTab = newTop.tabIndex;
        if (targetTab != stackManager.currentTabIndex) {
          stackManager.currentTabIndex = targetTab;
          currentTabIndex.value = targetTab;
        }
      }
    }
  } else {
    // Current tab is at its root (or navigator null) - remove the synthetic root entry and switch tabs
    stackManager.popRoute();
    final newTop = stackManager.currentRoute;
    if (newTop != null) {
      final targetTab = newTop.tabIndex;
      if (targetTab != stackManager.currentTabIndex) {
        stackManager.currentTabIndex = targetTab;
        currentTabIndex.value = targetTab;
      }
    }
  }
}

/// Pop until a specific route name (root navigator)
static void popUntil(String routeName) {
  final stackManager = _stackManager;
  final currentEntry = stackManager.currentRoute;
  if (currentEntry == null) return;

  final currentTab = currentEntry.tabIndex;
  final currentNavigator = _getNavigatorForTab(currentTab);
  
  if (currentNavigator != null) {
    currentNavigator.popUntil((route) => route.settings.name == routeName);
    // The observer will handle removing entries from the stack
  }
}

/// Navigate back using the global stack
/// Returns true if app should exit, false if navigation was handled
static Future<bool> navigateBack(BuildContext context) async {
  final stackManager = _stackManager;
  if (!stackManager.canPop()) {
    return true; // Allow app to close
  }

  final currentEntry = stackManager.currentRoute;
  if (currentEntry == null) {
    // No current route but stack says we can pop - reset to safe state
    stackManager.resetToDashboard();
    return true;
  }

  final currentTab = currentEntry.tabIndex;
  final currentNavigator = _getNavigatorForTab(currentTab);

  // Check if navigator exists, is not disposed, and can pop before popping
  if (currentNavigator != null) {
    try {
      // Normal case: there is a sub-page to pop within this tab
      if (currentNavigator.canPop()) {
        currentNavigator.pop();
        // The observer will remove this entry from the stack and handle tab switching if needed
        return false; // Navigation was handled
      } else {
        // Navigator exists but can't pop - fall back to stack management
        stackManager.popRoute();
        final newTop = stackManager.currentRoute;
        if (newTop != null) {
          final targetTab = newTop.tabIndex;
          if (targetTab != stackManager.currentTabIndex) {
            stackManager.currentTabIndex = targetTab;
            currentTabIndex.value = targetTab;
          }
        }
        return false; // Navigation was handled
      }
    } catch (e) {
      // If popping fails due to disposed navigator or other issues, fall back to stack management
      stackManager.popRoute();
      final newTop = stackManager.currentRoute;
      if (newTop != null) {
        final targetTab = newTop.tabIndex;
        if (targetTab != stackManager.currentTabIndex) {
          stackManager.currentTabIndex = targetTab;
          currentTabIndex.value = targetTab;
        }
      }
      return false; // Navigation was handled (via fallback)
    }
  } else {
    // Current tab is at its root (or navigator null) - remove the synthetic root entry and switch tabs
    stackManager.popRoute();
    final newTop = stackManager.currentRoute;
    if (newTop != null) {
      final targetTab = newTop.tabIndex;
      if (targetTab != stackManager.currentTabIndex) {
        stackManager.currentTabIndex = targetTab;
        currentTabIndex.value = targetTab;
      }
    }
    return false; // Navigation was handled
  }
}

   /// Helper to determine which tab a route belongs to
   static int _getTabIndexForRoute(String routeName) {
     switch (routeName) {
       case AppRoutes.dashboard:
         return 0;
       case AppRoutes.notes:
       case AppRoutes.savedNotes:
       case AppRoutes.flashcards:
       case AppRoutes.flashcardsReview:
       case AppRoutes.noteDetail:
         return 1;
       case AppRoutes.studyHub:
       case AppRoutes.shortNotes:
       case AppRoutes.progressDashboard:
       case AppRoutes.studySession:
         return 2;
       case AppRoutes.notifications:
         return 3;
       case AppRoutes.settings:
       case AppRoutes.editProfile:
         return 4;
       default:
         return _stackManager.currentTabIndex;
     }
   }
}

/// Global value notifier for tab index - accessible from anywhere
final currentTabIndex = ValueNotifier<int>(0);
