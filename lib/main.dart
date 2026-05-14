import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flashai/core/theme/app_theme.dart';
import 'package:flashai/core/theme/theme_provider.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/core/navigation/navigation_stack_observer.dart';
import 'package:flashai/core/presentation/screens/loading_screen.dart';
import 'package:flashai/features/auth/presentation/providers/auth_provider.dart';
import 'package:flashai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flashai/features/notes/presentation/screens/notes_screen.dart';
import 'package:flashai/features/study/presentation/screens/study_hub_screen.dart';
import 'package:flashai/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flashai/features/settings/presentation/screens/settings_screen.dart';
import 'package:flashai/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:flashai/features/study/presentation/screens/study_session_screen.dart';
import 'package:flashai/features/study/presentation/screens/short_notes_screen.dart';
import 'package:flashai/features/study/presentation/screens/progress_dashboard_screen.dart';
import 'package:flashai/features/notes/presentation/screens/saved_notes_screen.dart';
import 'package:flashai/features/flashcards/presentation/screens/flashcards_screen.dart';
import 'package:flashai/features/study/presentation/models/study_mode.dart';
import 'package:flashai/features/notes/presentation/services/notes_repository.dart';
import 'package:flashai/features/flashcards/presentation/services/flashcard_progress_repository.dart';
import 'package:flashai/services/firebase/firebase_service.dart';
import 'package:flashai/services/push/push_notification_service.dart';
import 'package:flashai/services/notification/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Detect system brightness preference to set appropriate system UI overlay
  final platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
  final isDark = platformBrightness == Brightness.dark;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ),
  );

  // Initialize Firebase
  try {
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue without Firebase for development
  }

  runApp(const FlashAIApp());
}

class FlashAIApp extends StatefulWidget {
  const FlashAIApp({super.key});

  @override
  State<FlashAIApp> createState() => _FlashAIAppState();
}

class _FlashAIAppState extends State<FlashAIApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotesRepository()),
        ChangeNotifierProvider(create: (_) => FlashcardProgressRepository()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => MaterialApp(
          title: 'FlashAI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorKey: NavigationService.navigatorKey,
          home: const LoadingScreen(),
           routes: {
             AppRoutes.dashboard: (context) => const DashboardScreen(),
             AppRoutes.notes: (context) => const NotesScreen(),
             AppRoutes.studyHub: (context) => const StudyHubScreen(),
             AppRoutes.notifications: (context) =>
                 const NotificationCenterScreen(),
             AppRoutes.settings: (context) => const SettingsScreen(),
             AppRoutes.shortNotes: (context) => const ShortNotesScreen(),
             AppRoutes.progressDashboard: (context) =>
                 const ProgressDashboardScreen(),
             AppRoutes.savedNotes: (context) => const SavedNotesScreen(),
             AppRoutes.flashcards: (context) => const FlashcardsScreen(),
             AppRoutes.editProfile: (context) => const EditProfileScreen(),
           },
          onGenerateRoute: (settings) {
            // Handle routes with required parameters
            switch (settings.name) {
              case AppRoutes.studySession:
                final args = settings.arguments as Map<String, dynamic>?;
                final mode =
                    args?['mode'] as StudyMode? ?? StudyMode.unreviewedOnly;
                return MaterialPageRoute(
                  builder: (context) => StudySessionScreen(mode: mode),
                  settings: settings,
                );
              default:
                return MaterialPageRoute(
                  builder: (context) => const LoadingScreen(),
                  settings: settings,
                );
            }
          },
        ),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  late final List<NavigationStackObserver> _navObservers = [
    NavigationStackObserver(),
    NavigationStackObserver(),
    NavigationStackObserver(),
    NavigationStackObserver(),
    NavigationStackObserver(),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize navigation stack with Dashboard as root
    NavigationService.initializeStack();
    NavigationService.setNavigatorKeys(_navigatorKeys);

    // Set up tab change listener
    currentTabIndex.addListener(_onTabChanged);
    NavigationService.stackManager.currentTabIndex = 0;

    _initializePushNotifications();
    Future.microtask(() {
      final notesRepo = context.read<NotesRepository>();
      final flashcardRepo = context.read<FlashcardProgressRepository>();
      notesRepo.setFlashcardProgressRepository(flashcardRepo);
      notesRepo.loadNotes();
      flashcardRepo.loadCards();
    });
  }

  Future<void> _initializePushNotifications() async {
    try {
      final pushService = PushNotificationService();
      final initialized = await pushService.initialize();
      if (initialized) {
        pushService.notificationStream.listen((notification) {
          final provider = context.read<NotificationProvider>();
          provider.addNotification(notification);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    final newIndex = currentTabIndex.value;
    if (newIndex != _selectedIndex && mounted) {
      // Update the stack manager's current tab index
      NavigationService.stackManager.currentTabIndex = newIndex;
      setState(() => _selectedIndex = newIndex);
    }
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    if (index != _selectedIndex) {
      // Determine the route name for the target tab root
      String routeName;
      switch (index) {
        case 0:
          routeName = AppRoutes.dashboard;
          break;
        case 1:
          routeName = AppRoutes.notes;
          break;
        case 2:
          routeName = AppRoutes.studyHub;
          break;
        case 3:
          routeName = AppRoutes.notifications;
          break;
        case 4:
          routeName = AppRoutes.settings;
          break;
        default:
          routeName = AppRoutes.dashboard;
      }
      // Push the tab root onto the global navigation stack
      NavigationService.stackManager.pushRoute(
        routeName,
        tabIndex: index,
        arguments: null,
      );
    }
    currentTabIndex.value = index;
  }

  Widget _buildNavigator(int index, Widget screen) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: [_navObservers[index]],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (context) => screen, settings: settings),
    );
  }

  /// Handle system back button or Android back gesture
  Future<bool> _handleWillPop() async {
    // Use the global navigation stack manager to handle back navigation
    final shouldExit = await NavigationService.navigateBack(context);
    return shouldExit;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _handleWillPop();
        if (shouldExit && mounted) {
          // Let the app exit naturally by returning true to the PopScope
          // The PopScope will handle the actual exit when shouldExit is true
          return;
        }
      },
      child: Scaffold(
         body: IndexedStack(
           index: _selectedIndex,
           children: [
             _buildNavigator(0, const DashboardScreen()),
             _buildNavigator(1, const NotesScreen()),
             _buildNavigator(2, const StudyHubScreen()),
             _buildNavigator(3, const NotificationCenterScreen()),
             _buildNavigator(4, const SettingsScreen()),
           ],
         ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          animationDuration: const Duration(milliseconds: 300),
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard_rounded, size: 22),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note_rounded, size: 22),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, size: 22),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              label: 'Study',
            ),
             NavigationDestination(
               icon: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: const Icon(Icons.notifications_rounded, size: 22),
               ),
               selectedIcon: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.primary.withValues(alpha: 0.15),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Icon(
                   Icons.notifications_rounded,
                   size: 22,
                   color: theme.colorScheme.primary,
                 ),
               ),
               label: 'Alerts',
             ),
             NavigationDestination(
               icon: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: const Icon(Icons.settings_rounded, size: 22),
               ),
               selectedIcon: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.primary.withValues(alpha: 0.15),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Icon(
                   Icons.settings_rounded,
                   size: 22,
                   color: theme.colorScheme.primary,
                 ),
               ),
               label: 'Settings',
             ),
           ],
         ),
       ),
     );
   }
 }
