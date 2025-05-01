import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Get the current and target index to determine animation direction
          final currentIndex = navigationShell.currentIndex;
          final previousIndex =
              0; // Default to 0 since previousIndex is not available

          // Determine if we're moving left or right
          final isMovingRight = currentIndex > previousIndex;

          // Create a slide transition based on direction
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(isMovingRight ? 1.0 : -1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
        child: GestureDetector(
          key: ValueKey<int>(navigationShell.currentIndex),
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;

            // Swiping from left to right (positive velocity)
            if (details.primaryVelocity! > 0) {
              if (navigationShell.currentIndex > 0) {
                // Provide haptic feedback
                HapticFeedback.mediumImpact();
                navigationShell.goBranch(navigationShell.currentIndex - 1);
              }
            }
            // Swiping from right to left (negative velocity)
            else if (details.primaryVelocity! < 0) {
              if (navigationShell.currentIndex < 2) {
                // Assuming you have 3 tabs (0, 1, 2)
                // Provide haptic feedback
                HapticFeedback.mediumImpact();
                navigationShell.goBranch(navigationShell.currentIndex + 1);
              }
            }
          },
          child: navigationShell,
        ),
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 70,
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.chat_bubble_outline,
                  Icons.chat_bubble,
                  'Chats',
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.person_outline,
                  Icons.person,
                  'Profile',
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.settings_outlined,
                  Icons.settings,
                  'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = navigationShell.currentIndex == index;

    return InkWell(
      onTap: () => _onTap(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
