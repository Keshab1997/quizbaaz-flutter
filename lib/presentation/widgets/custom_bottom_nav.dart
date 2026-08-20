import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'glass_card.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onCenterTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Glass Bar
          GlassCard(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
                _buildNavItem(icon: Icons.menu_book_rounded, label: 'Chapters', index: 1),
                const SizedBox(width: 48), // Space for center floating shield
                _buildNavItem(icon: Icons.leaderboard_rounded, label: 'Ranking', index: 2),
                _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
              ],
            ),
          ),

          // Center Raised Golden Button
          Positioned(
            top: -16,
            child: GestureDetector(
              onTap: onCenterTap,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGold.withOpacity(0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF0F172A),
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? AppColors.neonGold : AppColors.textSecondary,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.neonGold : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
