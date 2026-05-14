import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flashai/core/theme/app_theme.dart';
import 'package:flashai/features/auth/presentation/screens/login_screen.dart';
import 'package:flashai/features/auth/presentation/providers/auth_provider.dart';
import 'package:flashai/main.dart' show MainNavigationShell;

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Initialize auth state (checks if user is logged in via Remember Me)
    final authProvider = context.read<AuthProvider>();
    await authProvider.initializeAuthState();

    // Give the loading screen a nice 2-second display time
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Navigate based on authentication state
      if (authProvider.isAuthenticated) {
        // User is logged in, go to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        );
      } else {
        // User is not logged in, go to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo as central element
            Image.asset(
              'assets/icons/Layer 2.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // App name
            const Text(
              'FlashAI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'AI-Powered Learning',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
