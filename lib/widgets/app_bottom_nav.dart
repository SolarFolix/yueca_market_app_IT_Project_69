import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reused across Home, Analytics, Calendar and Settings/Profile screens.
/// [currentIndex]: 0 = Home, 1 = Analytics, 2 = Calendar, 3 = Profile.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNav({super.key, required this.currentIndex, this.onTap});

  static const _routes = ['/home', '/analytics', '/calendar', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _navItem(context, 0, Icons.home_rounded, 'Home'),
              _navItem(context, 1, Icons.bar_chart_rounded, 'Analytics'),
              _navItem(context, 2, Icons.calendar_month_rounded, 'Calendar'),
              _navItem(context, 3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label) {
    final bool selected = index == currentIndex;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          } else if (!selected) {
            Navigator.of(context).pushReplacementNamed(_routes[index]);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
