import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flashai/core/navigation/navigation_service.dart';

/// AppDrawer provides a comprehensive side navigation with active states
/// and organized menu sections
class AppDrawer extends StatelessWidget {
  final int currentIndex;

  const AppDrawer({
    super.key,
    required this.currentIndex,
  });

  static const List<_NavItem> _navItems = [
    _NavItem(
      index: 0,
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      description: 'Overview & analytics',
    ),
    _NavItem(
      index: 1,
      label: 'Notes',
      icon: Icons.edit_note_rounded,
      description: 'AI-powered notes',
    ),
    _NavItem(
      index: 2,
      label: 'Study',
      icon: Icons.school_rounded,
      description: 'Learn & review',
    ),
    _NavItem(
      index: 3,
      label: 'Alerts',
      icon: Icons.notifications_rounded,
      description: 'Notifications',
    ),
    _NavItem(
      index: 4,
      label: 'Settings',
      icon: Icons.settings_rounded,
      description: 'Preferences',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ..._navItems.map((item) => _buildNavItem(context, item, theme)),
                ],
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

   Widget _buildHeader(ThemeData theme) {
     return Container(
       padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
       decoration: BoxDecoration(
         gradient: const LinearGradient(
           colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ),
         borderRadius: const BorderRadius.only(
           bottomLeft: Radius.circular(24),
           bottomRight: Radius.circular(24),
         ),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Container(
                 width: 48,
                 height: 48,
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.2),
                   shape: BoxShape.circle,
                 ),
                 child: ClipOval(
                   child: Image.asset(
                     'assets/icons/Layer 2.png',
                     fit: BoxFit.cover,
                   ),
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text(
                       'FlashAI',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 22,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     Text(
                       'Learning Assistant',
                       style: TextStyle(
                         color: Colors.white70,
                         fontSize: 13,
                       ),
                     ),
                   ],
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.15),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                 const SizedBox(width: 6),
                 Text(
                   'Let\'s buildup your future with FlashAI',
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 12,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ],
             ),
           ),
         ],
       ),
     );
   }

  Widget _buildNavItem(BuildContext context, _NavItem item, ThemeData theme) {
    final isSelected = currentIndex == item.index;
    final textColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _navigateToRoute(context, item);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _FooterItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!)
                  .showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _FooterItem(
            icon: Icons.info_outline_rounded,
            label: 'About FlashAI',
            onTap: () {
              HapticFeedback.lightImpact();
              showAboutDialog(
                context: NavigationService.navigatorKey.currentContext!,
                applicationName: 'FlashAI',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.psychology_rounded, size: 48),
                applicationLegalese: '© 2024 FlashAI Team',
              );
            },
          ),
        ],
      ),
    );
  }

    void _navigateToRoute(BuildContext context, _NavItem item) {
      Navigator.of(context).pop(); // Close drawer

      Future.delayed(const Duration(milliseconds: 250), () {
        // Only switch if different tab
        if (currentTabIndex.value == item.index) return;
        // Push the corresponding tab root onto navigation stack
        String routeName;
        switch (item.index) {
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
        NavigationService.stackManager.pushRoute(
          routeName,
          tabIndex: item.index,
          arguments: null,
        );
        currentTabIndex.value = item.index;
      });
    }
}

/// Navigation item model
class _NavItem {
  final int index;
  final String label;
  final String description;
  final IconData icon;

  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.description,
  });
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterItem({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
