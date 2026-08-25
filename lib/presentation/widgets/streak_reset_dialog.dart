import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/user_provider.dart';
import '../screens/shop/shop_screen.dart';
import 'glass_card.dart';

/// Popup dialog shown when a user misses a day and their Daily Streak is reset.
class StreakResetDialog extends StatelessWidget {
  final StreakResetDetails details;

  const StreakResetDialog({
    super.key,
    required this.details,
  });

  static Future<void> show(BuildContext context, StreakResetDetails details) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StreakResetDialog(details: details),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassCard(
        borderRadius: 24,
        borderColor: AppColors.neonRed.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D Fire Icon / Illustration
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonRed.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonRed.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  AppAssets.streakFire,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_fire_department_rounded,
                    size: 64,
                    color: AppColors.neonRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Header Title
            const Text(
              '💔 Daily Streak Reset!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'You missed yesterday\'s quiz and lost your ${details.lostStreak}-Day Streak!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Streak Shield Recovery Box
            if (details.hasShield) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_moon_rounded, color: AppColors.neonGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Streak Freeze Shield Available!',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use 1 Streak Shield from your inventory to restore your ${details.lostStreak}-Day Streak immediately!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final restored = userProvider.restoreStreakWithShield(details.lostStreak);
                          Navigator.pop(context);
                          if (restored) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🛡️ ${details.lostStreak}-Day Streak restored successfully!'),
                                backgroundColor: AppColors.neonGreen,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.security_rounded, size: 18),
                        label: const Text(
                          'Restore Streak Now',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Prompt to Buy Shield
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_moon_outlined, color: AppColors.neonGold, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Get a Streak Shield in the Shop to protect future streaks!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
                      },
                      child: const Text('Get Shield', style: TextStyle(color: AppColors.neonGold, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  details.hasShield ? 'No Thanks, Start Fresh' : 'Keep Going & Rebuild',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
