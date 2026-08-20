import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    final shopItems = [
      {'name': '50-50 Lifeline (x3)', 'desc': 'Eliminates 2 wrong options', 'cost': 150, 'currency': 'Coins', 'icon': Icons.filter_2},
      {'name': '+10s Freeze Time (x2)', 'desc': 'Freezes the clock during quiz', 'cost': 200, 'currency': 'Coins', 'icon': Icons.ac_unit},
      {'name': 'Streak Freeze Shield', 'desc': 'Protects streak if you miss a day', 'cost': 20, 'currency': 'Gems', 'icon': Icons.shield_moon},
      {'name': 'Exclusive VIP Golden Avatar', 'desc': 'Unlocks 3D glowing character', 'cost': 50, 'currency': 'Gems', 'icon': Icons.workspace_premium},
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Power-Up Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Balance Bar
          GlassCard(
            borderRadius: 20,
            borderColor: AppColors.neonCyan.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.neonGold, size: 24),
                    const SizedBox(width: 8),
                    Text('${user.coins} Coins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonGold)),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.white24),
                Row(
                  children: [
                    const Icon(Icons.diamond, color: AppColors.neonPurple, size: 24),
                    const SizedBox(width: 8),
                    Text('${user.gems} Gems', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'AVAILABLE POWER-UPS & ITEMS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),

          ...shopItems.map((item) {
            final isGems = item['currency'] == 'Gems';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassCard(
                borderRadius: 18,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isGems ? AppColors.neonPurple.withOpacity(0.2) : AppColors.neonGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item['icon'] as IconData, color: isGems ? AppColors.neonPurple : AppColors.neonGold),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(item['desc'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isGems ? AppColors.neonPurple : AppColors.neonGold,
                        foregroundColor: isGems ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✨ Purchased ${item['name']}!')),
                        );
                      },
                      child: Text(
                        '${item['cost']} ${item['currency']}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
