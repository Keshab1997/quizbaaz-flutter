import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Admin Web Control Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Live Metrics
          const Text('SYSTEM OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1,284', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neonCyan)),
                      Text('Active Live Users', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('8,420', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neonGold)),
                      Text('Guest Visitors', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action 1: Upload JSON Questions
          GlassCard(
            borderRadius: 20,
            borderColor: AppColors.neonPurple.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.upload_file, color: AppColors.neonPurple),
                    SizedBox(width: 8),
                    Text('Upload JSON / Excel Question Bank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Import batch question JSON files for Chapters and Daily Live Quizzes.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                NeonButton(
                  text: 'Upload Batch JSON File',
                  height: 42,
                  gradient: AppColors.primaryGradient,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ 50 Questions successfully parsed & added to Question Bank!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action 2: Declare Daily Winner & Gift
          GlassCard(
            borderRadius: 20,
            borderColor: AppColors.neonGold.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppColors.neonGold),
                    SizedBox(width: 8),
                    Text("Declare Yesterday's Champions & Gifts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Automatically snap leaderboard and dispatch winner badges & courier parcels.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                NeonButton(
                  text: 'Publish Champions & Gifts',
                  height: 42,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🎉 Yesterday's champions and gifts announced globally!")),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Anti Cheat & Maintenance
          GlassCard(
            borderRadius: 20,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Anti-Cheat Auto Protection', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Auto-flag suspicious fast answers & block bots', style: TextStyle(fontSize: 11)),
                  value: true,
                  activeColor: AppColors.neonGreen,
                  onChanged: (val) {},
                ),
                const Divider(color: Colors.white12),
                SwitchListTile(
                  title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Temporarily lock app for server upgrade', style: TextStyle(fontSize: 11)),
                  value: false,
                  activeColor: AppColors.neonRed,
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
