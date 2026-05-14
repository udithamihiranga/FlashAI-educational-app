import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flashai/features/dashboard/presentation/widgets/app_drawer.dart';
import 'package:flashai/features/auth/presentation/screens/login_screen.dart';
import 'package:flashai/features/auth/presentation/providers/auth_provider.dart';
import 'package:flashai/core/navigation/navigation_service.dart';
import 'package:flashai/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';

/// SettingsScreen displays user preferences and app configuration options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Detect system brightness and sync theme after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.detectSystemBrightness();
    });
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

   /// Handle logout action
   void _handleLogout() async {
     // Sign out using AuthProvider to clear all stored data
     final authProvider = context.read<AuthProvider>();
     await authProvider.signOut();

     if (mounted) {
       // Navigate to login screen and clear navigation stack using root navigator
       Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
         MaterialPageRoute(builder: (_) => const LoginScreen()),
         (route) => false,
       );
     }
   }

  void _toggleDarkMode(bool value) {
    HapticFeedback.lightImpact();

    // Update theme via ThemeProvider
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.toggleTheme(value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Dark mode enabled' : 'Dark mode disabled'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSettingsGroup(
    ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.outline.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_rounded, size: 20, color: Colors.white),
            ),
          ),
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(currentIndex: 4),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingsGroup(
              theme,
              title: 'APPEARANCE',
              children: [
                SwitchListTile(
                  value: context.watch<ThemeProvider>().isDarkMode,
                  onChanged: _toggleDarkMode,
                  secondary: Icon(
                    Icons.dark_mode_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch to dark theme'),
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
              _buildSettingsGroup(
                theme,
                title: 'ACCOUNT',
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(context.watch<AuthProvider>().userEmail ?? 'No email'),
                    subtitle: const Text('Free Plan'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Upgrade'),
                    ),
                  ),
                  const Divider(height: 32),
                  _SettingsTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Change username and photo',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.editProfile);
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Help & Support',
                    subtitle: 'Get assistance',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & Support coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle: 'Read our policy',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy Policy coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    title: Text(
                      'Log Out',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Sign out of your account'),
                    onTap: _showLogoutDialog,
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            _buildSettingsGroup(
              theme,
              title: 'ABOUT',
              children: [
                _SettingsTile(
                  icon: Icons.info_rounded,
                  title: 'About FlashAI',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showAboutDialog(
                      context: context,
                      applicationName: 'FlashAI',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.psychology_rounded,
                        size: 48,
                      ),
                      applicationLegalese: '© 2024 FlashAI Team',
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.feedback_rounded,
                  title: 'Send Feedback',
                  subtitle: 'Help us improve',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback feature coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.star_rounded,
                  title: 'Rate the App',
                  subtitle: '5 stars would be amazing',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rating feature coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Made by FlashAI Team',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// _SettingsTile is a styled list tile for settings options
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
