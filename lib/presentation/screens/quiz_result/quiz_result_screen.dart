import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'review_answers_screen.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final userProvider = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final isGuest = userProvider.user.isGuest;

    final totalQuestions = quiz.questions.length;
    final score = quiz.score;
    final correct = quiz.correctCount;
    final wrong = quiz.wrongCount;

    // Actual rewards credited to the player's balance.
    final coinsEarned = quiz.earnedCoins;
    final gemsEarned = quiz.earnedGems;
    final rewardSkipped = quiz.dailyRewardSkipped;
    final isPerfect = correct == totalQuestions && totalQuestions > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonGold.withValues(alpha: 0.15),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Trophy / 3D Asset — show the player's selected avatar
                  // (local asset or cloud/Google photo) instead of a hardcoded mascot.
                  Center(
                    child: _ResultAvatar(
                      avatar: userProvider.user.effectiveAvatar,
                      fallbackAsset: AppAssets.heroBoy,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'QUIZ COMPLETED! 🎉',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Awesome job! Here is your performance summary:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Score Glass Card
                  GlassCard(
                    borderRadius: 24,
                    borderColor: AppColors.neonGold.withValues(alpha: 0.4),
                    backgroundColor: const Color(0x33281E48),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL SCORE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.neonGold,
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Correct', '$correct', AppColors.neonGreen, Icons.check_circle),
                            _buildStatColumn('Wrong', '$wrong', AppColors.neonRed, Icons.cancel),
                            _buildStatColumn('Coins', '+$coinsEarned', AppColors.neonGold, Icons.monetization_on),
                            _buildStatColumn('Gems', '+$gemsEarned', AppColors.neonPurple, Icons.diamond),
                          ],
                        ),
                        if (isPerfect) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.neonGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              '🔥 PERFECT SCORE! +100 coin bonus',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neonGold,
                              ),
                            ),
                          ),
                        ],
                        if (rewardSkipped) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'ℹ️ Today\'s daily reward already claimed — play again tomorrow!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Guest Conversion Card (If Guest)
                  if (isGuest) ...[
                    GlassCard(
                      borderColor: AppColors.neonCyan.withValues(alpha: 0.4),
                      backgroundColor: const Color(0x33003B46),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.workspace_premium, color: AppColors.neonCyan, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save Your Score & Join the Leaderboard!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neonCyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'You played as Guest. Sign in with 1-tap Google account to register your score on the daily leaderboard.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          NeonButton(
                            text: auth.isBusy ? 'Signing in...' : '1-Tap Google Sign-In',
                            height: 40,
                            gradient: AppColors.primaryGradient,
                            onPressed: auth.isBusy
                                ? () {}
                                : () => _handleGoogleSignIn(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  NeonButton(
                    text: 'CHECK LEADERBOARD 🏆',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    text: 'REVIEW ANSWERS 📖',
                    gradient: const LinearGradient(
                      colors: [AppColors.neonCyan, AppColors.neonPurple],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReviewAnswersScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text(
                      'Back to Home Dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (auth.isBusy) return;

    try {
      final signedIn = await auth.signInWithGoogle();
      if (!signedIn) return; // User cancelled the account picker.

      final user = auth.firebaseUser;
      if (user == null) return;

      await userProvider.linkGoogleAccount(
        user.displayName ?? user.email ?? 'Player',
        user.email ?? user.uid,
        photoURL: user.photoURL,
        uid: user.uid,
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('🎉 Signed in with Google! Score saved to Leaderboard!')),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade800),
      );
    }
  }

  Widget _buildStatColumn(String title, String val, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Shows the player's selected profile avatar (local asset or cloud/Google
/// photo). Falls back to the classic mascot when the avatar can't be loaded.
class _ResultAvatar extends StatelessWidget {
  final String avatar;
  final String fallbackAsset;

  const _ResultAvatar({required this.avatar, required this.fallbackAsset});

  bool get _isRemote =>
      avatar.startsWith('http://') || avatar.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isRemote) {
      return Image.network(
        avatar,
        height: 150,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          fallbackAsset,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.military_tech,
            size: 90,
            color: AppColors.neonGold,
          ),
        ),
      );
    }
    return Image.asset(
      avatar.isNotEmpty ? avatar : fallbackAsset,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.military_tech,
        size: 90,
        color: AppColors.neonGold,
      ),
    );
  }
}
