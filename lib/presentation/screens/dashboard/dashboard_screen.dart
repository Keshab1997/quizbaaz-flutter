import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/streak_flame_widget.dart';
import '../../widgets/champion_podium_widget.dart';
import '../../widgets/custom_bottom_nav.dart';
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

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final yesterdayChamp = userProvider.yesterdayTopChampion;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background Gradient Glows
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(0.12),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER
                  _buildHeader(user),
                  const SizedBox(height: 18),

                  // 2. HERO SECTION
                  _buildHeroSection(),
                  const SizedBox(height: 16),

                  // 3. LIVE PLAYERS MINI BAR
                  _buildLivePlayersCard(),
                  const SizedBox(height: 16),

                  // 4. YESTERDAY'S CHAMPION PODIUM
                  ChampionPodiumWidget(
                    champion: yesterdayChamp,
                    onViewProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen(initialTabIndex: 1)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. DAILY STREAK WIDGET
                  StreakFlameWidget(streakDays: user.dailyStreak),
                  const SizedBox(height: 20),

                  // 6. CATEGORY QUICK MENU (5 ACTION BUTTONS)
                  const Text(
                    'EXPLORE & PLAY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryGrid(),
                  const SizedBox(height: 16),

                  // Admin Shortcut Pill
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings, size: 16, color: AppColors.neonCyan),
                      label: const Text(
                        'Open Admin Web Control Panel',
                        style: TextStyle(color: AppColors.neonCyan, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Floating Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
              onCenterTap: _startDailyQuiz,
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader(dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Profile & Welcome Text
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonCyan, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  user.avatarPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user.fullName.split(' ').first}! 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  "Let's test your knowledge",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Currency Counter & Notification
        Row(
          children: [
            // Coins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, size: 16, color: AppColors.neonGold),
                  const SizedBox(width: 4),
                  Text(
                    '${user.coins}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Gems
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond, size: 16, color: AppColors.neonPurple),
                  const SizedBox(width: 4),
                  Text(
                    '${user.gems}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- HERO SECTION CARD ---
  Widget _buildHeroSection() {
    return GlassCard(
      borderRadius: 24,
      borderColor: AppColors.neonPurple.withOpacity(0.4),
      backgroundColor: const Color(0x332E1065),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neonCyan.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'TODAY’S LIVE QUIZ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neonCyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '10 Questions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppColors.neonGold),
                        SizedBox(width: 4),
                        Text(
                          '03:20 MIN  •  500 Coins 🪙',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: 'START QUIZ >',
                      height: 44,
                      onPressed: _startDailyQuiz,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Image.asset(
                    AppAssets.heroBoy,
                    height: 145,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.military_tech,
                      size: 90,
                      color: AppColors.neonGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LIVE PLAYERS CARD ---
  Widget _buildLivePlayersCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 16,
      borderColor: AppColors.neonGreen.withOpacity(0.3),
      child: Row(
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
                'LIVE PLAYERS (1,284 Online)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Text(
            '🔥 Fast Competition',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.neonGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- CATEGORY GRID (5 ACTION BUTTONS) ---
  Widget _buildCategoryGrid() {
    final items = [
      {
        'title': 'Chapter Quiz',
        'icon': AppAssets.chapterQuiz,
        'color': AppColors.neonCyan,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChapterListScreen())),
      },
      {
        'title': 'Practice Mode',
        'icon': AppAssets.practiceTarget,
        'color': AppColors.neonGreen,
        'action': _startDailyQuiz,
      },
      {
        'title': '1 vs 1 Battle',
        'icon': AppAssets.battleSwords,
        'color': AppColors.neonPink,
        'action': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚔️ 1 vs 1 Battle matchmaking opening soon!')),
          );
        },
      },
      {
        'title': 'Rewards & Gifts',
        'icon': AppAssets.giftBox,
        'color': AppColors.neonGold,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
      },
      {
        'title': 'Power Shop',
        'icon': AppAssets.shopStall,
        'color': AppColors.neonPurple,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GlassCard(
          padding: const EdgeInsets.all(10),
          borderRadius: 16,
          borderColor: (item['color'] as Color).withOpacity(0.3),
          onTap: item['action'] as VoidCallback,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                item['icon'] as String,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.games,
                  color: item['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
