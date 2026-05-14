import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashai/main.dart';
import 'package:flashai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flashai/features/notes/presentation/screens/notes_screen.dart';
import 'package:flashai/features/flashcards/presentation/screens/flashcards_screen.dart';
import 'package:flashai/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flashai/features/settings/presentation/screens/settings_screen.dart';

void main() {
  group('FlashAI App Integration Tests', () {
    testWidgets('App launches and displays main navigation shell', (WidgetTester tester) async {
      await tester.pumpWidget(const FlashAIApp());
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('Dashboard screen loads with correct elements', (WidgetTester tester) async {
      await tester.pumpWidget(const FlashAIApp());
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.textContaining('Hello, Student'), findsOneWidget);
      expect(find.text('Learning Progress'), findsOneWidget);
      expect(find.text('Your Stats'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('Navigation between tabs works', (WidgetTester tester) async {
      await tester.pumpWidget(const FlashAIApp());
      
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.byType(NotesScreen), findsOneWidget);
      
      await tester.tap(find.text('Flashcards'));
      await tester.pumpAndSettle();
      expect(find.byType(FlashcardsScreen), findsOneWidget);
      
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationCenterScreen), findsOneWidget);
      
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Notification center displays with notifications', (WidgetTester tester) async {
      await tester.pumpWidget(const FlashAIApp());
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('Sarah'), findsOneWidget);
    });
  });
}