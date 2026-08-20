import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../daily_quiz/daily_quiz_screen.dart';
import '../chapter_quiz/chapter_list_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../rewards/rewards_screen.dart';
import '../shop/shop_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  bool _isFemaleMascot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadInitialData();
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChapterListScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    }
  }

  void _startDailyQuiz() {
    context.read<QuizProvider>().startDailyQuiz();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DailyQuizScreen()),
    );
  }

  void _toggleMascotGender() {
    setState(() {
      _isFemaleMascot = !_isFemaleMascot;
    });
    final user = context.read<UserProvider>().user;
    user.toggleGender();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    final heroMascotAsset = _isFemaleMascot ? AppAssets.heroGirl : AppAssets.heroBoy;
    final userAvatarAsset = _isFemaleMascot ? AppAssets.femaleAvatar : AppAssets.maleAvatar;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background Gradient Glow Orbs (Seamless Dark Navy & Purple)
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            top: 320,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(0.14),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonGold.withOpacity(0.12),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= 1. TOP HEADER =================
                  _buildTopHeader(user, userAvatarAsset),
                  const SizedBox(height: 16),

                  // ================= 2. MAIN HERO TODAY'S QUIZ CARD =================
                  _buildMainHeroCard(heroMascotAsset),
                  const SizedBox(height: 14),

                  // ================= 3. LIVE PLAYERS CARD =================
                  _buildLivePlayersCard(),
                  const SizedBox(height: 14),

                  // ================= 4. YESTERDAY'S CHAMPION =================
                  _buildYesterdayChampionCard(),
                  const SizedBox(height: 14),

                  // ================= 5. DAILY STREAK =================
                  _buildDailyStreakCard(),
                  const SizedBox(height: 14),

                  // ================= 6. LEADERBOARD PREVIEW =================
                  _buildLeaderboardPreviewCard(),
                  const SizedBox(height: 20),

                  // ================= 7. QUICK ACTIONS (5 3D SHORTCUTS) =================
                  const Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 18),

                  // Admin Web Shortcut
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        );
                      },
                      icon: const Icon(Icons.shield_rounded, size: 16, color: AppColors.neonCyan),
                      label: const Text(
                        'Open Admin Web Control Panel',
                        style: TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= 8. BOTTOM NAVIGATION =================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  // --- 1. TOP HEADER ---
  Widget _buildTopHeader(UserModel user, String avatarAsset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Circular 3D Avatar (Tap to toggle Boy/Girl) + Greeting
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleMascotGender,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPurple.withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      avatarAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${user.fullName}! 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    "Let's test your knowledge",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),

        // Right: Coins + Purple Gem + Notification Bell with Red Dot
        Row(
          children: [
            // Gold Coins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neonGold.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Image.asset(AppAssets.coinGem, width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${user.coins}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Purple Diamond / Gem
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${user.gems}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Notification Bell with Red Indicator
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 18, color: Colors.white),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.neonRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.neonRed, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. MAIN HERO TODAY'S QUIZ CARD ---
  Widget _buildMainHeroCard(String heroMascotAsset) {
    return GlassCard(
      borderRadius: 24,
      borderColor: AppColors.neonPurple.withOpacity(0.4),
      backgroundColor: const Color(0x332E1065),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              // Mascot on Left Side holding Golden Trophy
              Expanded(
                flex: 4,
                child: Image.asset(
                  heroMascotAsset,
                  height: 155,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.military_tech,
                    size: 90,
                    color: AppColors.neonGold,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Details on Right Side
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neonCyan.withOpacity(0.4)),
                      ),
                      child: const Text(
                        "TODAY'S QUIZ",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonCyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '10 QUESTIONS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Timer & Rewards
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 12, color: AppColors.neonGold),
                              SizedBox(width: 4),
                              Text(
                                '03:20 MIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neonGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Text('🎁', style: TextStyle(fontSize: 10)),
                              SizedBox(width: 4),
                              Text(
                                '500 Coins',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Premium Yellow/Orange START QUIZ → Button
                    NeonButton(
                      text: 'START QUIZ  →',
                      height: 44,
                      glowColor: AppColors.neonGold,
                      gradient: AppColors.goldGradient,
                      onPressed: _startDailyQuiz,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. LIVE PLAYERS CARD ---
  Widget _buildLivePlayersCard() {
    final sampleLivePlayers = [
      {'name': 'Rahul', 'status': 'Playing 🟢', 'avatar': AppAssets.championBoy},
      {'name': 'Amit', 'status': 'Q. 7/10 🟢', 'avatar': AppAssets.maleAvatar},
      {'name': 'Suman', 'status': 'Q. 9/10 🟢', 'avatar': AppAssets.femaleAvatar},
      {'name': 'Priya', 'status': 'Finished 🟢', 'avatar': AppAssets.femaleAvatar},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      borderColor: AppColors.neonGreen.withOpacity(0.35),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonGreen,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '1,284 Online',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚡ 1,284 active quiz players online!')),
                  );
                },
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonCyan,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal scrolling mini player cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: sampleLivePlayers.map((player) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: AssetImage(player['avatar'] as String),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player['name'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            player['status'] as String,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neonGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. YESTERDAY'S CHAMPION CARD ---
  Widget _buildYesterdayChampionCard() {
    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonGold.withOpacity(0.4),
      backgroundColor: const Color(0x33281E48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('👑', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    "YESTERDAY'S CHAMPION",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen(initialTabIndex: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neonGold.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'VIEW PROFILE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonGold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 3D Winner on Podium with Golden Trophy
              Container(
                width: 75,
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonPurple.withOpacity(0.4),
                      AppColors.neonGold.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Image.asset(
                  AppAssets.championBoy,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              // Rahul Das, Score: 96/100, Rank #1, Reward: 500 Coins
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rahul Das',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Score: 96/100  •  Rank #1 🏆',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neonGold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, size: 14, color: AppColors.neonPink),
                        SizedBox(width: 4),
                        Text(
                          'Reward: 500 Coins + Smartwatch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. DAILY STREAK CARD ---
  Widget _buildDailyStreakCard() {
    final streakDaysList = [true, true, true, true, true, true, false]; // 6 days completed

    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonGold.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(AppAssets.streakFire, width: 34, height: 34),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY STREAK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonGold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '6 DAYS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 7-day progress indicator: ✓ ✓ ✓ ✓ ✓ ✓ ○
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: streakDaysList.map((isDone) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.neonGold.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isDone ? AppColors.neonGold : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: AppColors.neonGold)
                      : const Text('○', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Complete 7 days streak to get 500 bonus coins!',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. LEADERBOARD PREVIEW CARD ---
  Widget _buildLeaderboardPreviewCard() {
    final topRanks = [
      {'rank': '🥇', 'name': 'Rahul', 'score': 96, 'color': AppColors.neonGold},
      {'rank': '🥈', 'name': 'Amit', 'score': 91, 'color': const Color(0xFFC0C0C0)},
      {'rank': '🥉', 'name': 'Suman', 'score': 89, 'color': const Color(0xFFCD7F32)},
      {'rank': '4.', 'name': 'Arjun', 'score': 87, 'color': AppColors.textSecondary},
      {'rank': '5.', 'name': 'Priya', 'score': 82, 'color': AppColors.textSecondary},
    ];

    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonCyan.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🏆', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    'LEADERBOARD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonCyan,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                  );
                },
                child: const Text(
                  'VIEW FULL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonCyan,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...topRanks.map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      p['rank'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p['name'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${p['score']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: p['color'] as Color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- 7. QUICK ACTIONS (5 3D SHORTCUT CARDS) ---
  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'title': 'Chapter Quiz',
        'icon': AppAssets.chapterQuiz,
        'color': AppColors.neonCyan,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChapterListScreen())),
      },
      {
        'title': 'Practice',
        'icon': AppAssets.practiceTarget,
        'color': AppColors.neonGreen,
        'onTap': _startDailyQuiz,
      },
      {
        'title': '1 vs 1 Battle',
        'icon': AppAssets.battleSwords,
        'color': AppColors.neonPink,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚔️ 1 vs 1 Realtime Battle Arena Ready!')),
          );
        },
      },
      {
        'title': 'Rewards',
        'icon': AppAssets.giftBox,
        'color': AppColors.neonGold,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
      },
      {
        'title': 'Shop',
        'icon': AppAssets.shopStall,
        'color': AppColors.neonPurple,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((act) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              borderRadius: 16,
              borderColor: (act['color'] as Color).withOpacity(0.35),
              onTap: act['onTap'] as VoidCallback,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    act['icon'] as String,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    act['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 8. BOTTOM NAVIGATION (Home, Quiz, Ranking, Profile) ---
  Widget _buildBottomNav() {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 🏠 Home (Glowing Gold Highlight)
            _buildBottomNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: _currentNavIndex == 0,
              onTap: () => _onNavTap(0),
            ),
            // ❓ Quiz
            _buildBottomNavItem(
              icon: Icons.help_outline_rounded,
              label: 'Quiz',
              isActive: _currentNavIndex == 1,
              onTap: () => _onNavTap(1),
            ),
            // 🏆 Ranking
            _buildBottomNavItem(
              icon: Icons.emoji_events_rounded,
              label: 'Ranking',
              isActive: _currentNavIndex == 2,
              onTap: () => _onNavTap(2),
            ),
            // 👤 Profile (Tap to toggle Boy/Girl Avatar)
            _buildBottomNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isActive: _currentNavIndex == 3,
              onTap: () => _onNavTap(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? AppColors.neonGold : AppColors.textSecondary,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              color: isActive ? AppColors.neonGold : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
