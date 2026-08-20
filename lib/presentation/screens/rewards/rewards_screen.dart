import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../widgets/glass_card.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myGifts = [
      {
        'title': 'Fire-Boltt 3D Smartwatch',
        'type': 'Physical Gift',
        'status': 'Processing Delivery',
        'icon': AppAssets.giftBox,
        'date': 'Yesterday (Aug 19)',
        'claimed': true,
      },
      {
        'title': '₹500 Amazon Gift Voucher',
        'type': 'Digital Code',
        'status': 'Code: AMZN-QUIZ-9981',
        'icon': AppAssets.coinGem,
        'date': 'Aug 15, 2026',
        'claimed': true,
      }
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('My Rewards & Gifts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Banner
          GlassCard(
            borderRadius: 20,
            borderColor: AppColors.neonGold.withValues(alpha: 0.4),
            backgroundColor: const Color(0x33281E48),
            child: Row(
              children: [
                Image.asset(AppAssets.giftBox, width: 70, height: 70),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Win Daily Real Gifts!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonGold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Finish #1 in Daily Live Quiz to receive high-tech gadgets & vouchers delivered to your home.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'CLAIMED GIFTS & PRIZES',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),

          ...myGifts.map((gift) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassCard(
                borderRadius: 18,
                child: Row(
                  children: [
                    Image.asset(gift['icon'] as String, width: 48, height: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gift['title'] as String,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gift['status'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neonCyan),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gift['date'] as String,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
