import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Avatar & Info
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.neonCyan, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(45),
                      child: Image.asset(
                        user.avatarPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(fontSize: 13, color: AppColors.neonCyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
                        const SizedBox(height: 6),
                        Text('${user.dailyStreak} Days', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('Current Streak', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events, color: AppColors.neonGold, size: 28),
                        SizedBox(height: 6),
                        Text('92.4%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Win Accuracy', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Badges
            GlassCard(
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BADGES & ACHIEVEMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBadge('Top 1 Winner', Icons.military_tech, AppColors.neonGold),
                      _buildBadge('7 Day Streak', Icons.whatshot, Colors.orangeAccent),
                      _buildBadge('Speed Demon', Icons.bolt, AppColors.neonCyan),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mode switcher (Guest / User)
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.white.withValues(alpha: 0.05),
              leading: const Icon(Icons.swap_horiz, color: AppColors.neonCyan),
              title: Text(user.isGuest ? 'Currently: Guest Mode' : 'Currently: Registered User'),
              subtitle: Text(user.isGuest ? 'Tap to switch to Full User' : 'Tap to test Guest Mode'),
              trailing: Switch(
                value: !user.isGuest,
                activeThumbColor: AppColors.neonCyan,
                onChanged: (val) {
                  userProvider.setGuestMode(!val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Google Account
            GlassCard(
              borderRadius: 16,
              child: Row(
                children: [
                  const Icon(Icons.g_mobiledata, size: 34, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isSignedIn
                              ? (auth.firebaseUser?.displayName ?? 'Google Account')
                              : 'Google Account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.isSignedIn
                              ? auth.firebaseUser?.email ?? 'Connected'
                              : 'Sign in to save your progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: auth.isSignedIn ? AppColors.neonGreen : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (auth.isSignedIn)
                    TextButton(
                      onPressed: () => auth.signOut(),
                      child: const Text('Sign Out', style: TextStyle(color: AppColors.neonRed, fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: auth.isBusy ? null : () => _handleGoogleSignIn(context),
                      child: Text(
                        auth.isBusy ? 'Wait...' : 'Sign In',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final signedIn = await auth.signInWithGoogle();
      if (!signedIn) return;

      final user = auth.firebaseUser;
      if (user == null) return;

      userProvider.linkGoogleAccount(
        user.displayName ?? 'QuizBaaz Player',
        user.email ?? 'player@quizbaaz.app',
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('🎉 Signed in with Google!')),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}
