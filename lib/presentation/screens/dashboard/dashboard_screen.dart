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
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
    } else if (index == 4) {
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
    final topPlayers = userProvider.leaderboard.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background Gradient Glow Orbs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
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
                  // ================= 1. TOP BAR (HEADER) =================
                  _buildHeader(user),
                  const SizedBox(height: 16),

                  // ================= 2. HERO SECTION (DUAL CARDS) =================
                  _buildHeroSection(),
                  const SizedBox(height: 16),

                  // ================= 3. MIDDLE WIDGETS SECTION =================
                  // Widget 1: Yesterday's Champion
                  ChampionPodiumWidget(
                    champion: yesterdayChamp,
                    onViewProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen(initialTabIndex: 1)),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Widget 2: Daily Streak (3D Fire + 6 Days + Week Tracker)
                  StreakFlameWidget(streakDays: user.dailyStreak),
                  const SizedBox(height: 14),

                  // Widget 3: Leaderboard (Top 5 Players List)
                  _buildTop5LeaderboardWidget(topPlayers),
                  const SizedBox(height: 20),

                  // ================= 4. QUIZ CATEGORY MENU (5 BUTTONS GRID) =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QUIZ CATEGORIES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChapterListScreen()));
                        },
                        child: const Text(
                          'View All >',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFiveCategoryGrid(),
                  const SizedBox(height: 16),

                  // Admin Quick Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        );
                      },
                      icon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.neonCyan),
                      label: const Text(
                        'Open Admin Web Control Panel',
                        style: TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= 5. BOTTOM NAVIGATION BAR =================
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

  // --- 1. HEADER WIDGET ---
  Widget _buildHeader(dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Profile Avatar + Welcome Greeting
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPurple.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  user.avatarPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user.fullName.split(' ').first}! 👋',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  "Let's test your knowledge",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Coins + Gems + Notification Bell
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
                      fontWeight: FontWeight.w800,
                      color: AppColors.neonGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Purple Gems
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Text('💎', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text(
                    '45',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neonPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Notification Bell with unread dot
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
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.neonPink,
                      shape: BoxShape.circle,
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

  // --- 2. HERO SECTION (Main Card + Live Players Card) ---
  Widget _buildHeroSection() {
    return Column(
      children: [
        // Left/Main Hero Card
        GlassCard(
          borderRadius: 24,
          borderColor: AppColors.neonPurple.withOpacity(0.4),
          backgroundColor: const Color(0x332E1065),
          child: Stack(
            clipBehavior: Clip.none,
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
                            "TODAY'S QUIZ",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.neonCyan,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                        // Timer & Reward Chest
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
                        // Big Yellow START QUIZ > Button
                        NeonButton(
                          text: 'START QUIZ >',
                          height: 44,
                          glowColor: AppColors.neonGold,
                          gradient: AppColors.goldGradient,
                          onPressed: _startDailyQuiz,
                        ),
                      ],
                    ),
                  ),
                  // 3D Cartoon Character Standing
                  Expanded(
                    flex: 4,
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
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Right / Live Players Card
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: 16,
          borderColor: AppColors.neonGreen.withOpacity(0.35),
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
              // Overlapping player avatars
              Row(
                children: [
                  _buildMiniAvatar(AppAssets.championBoy),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: _buildMiniAvatar(AppAssets.userAvatarBoy),
                  ),
                  Transform.translate(
                    offset: const Offset(-16, 0),
                    child: _buildMiniAvatar(AppAssets.heroBoy),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAvatar(String asset) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }

  // --- 3. TOP 5 LEADERBOARD WIDGET ---
  Widget _buildTop5LeaderboardWidget(List<dynamic> players) {
    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonCyan.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.leaderboard_rounded, color: AppColors.neonCyan, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'TOP 5 LEADERBOARD',
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
                  'Full Ranking >',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            const Text('Loading rankings...', style: TextStyle(fontSize: 11, color: AppColors.textMuted))
          else
            ...players.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              final rank = idx + 1;
              final isTop3 = rank <= 3;
              final rankColor = rank == 1
                  ? AppColors.neonGold
                  : (rank == 2 ? const Color(0xFFC0C0C0) : (rank == 3 ? const Color(0xFFCD7F32) : AppColors.textSecondary));

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rankColor.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: AssetImage(
                        p.avatarPath.isNotEmpty ? p.avatarPath : AppAssets.userAvatarBoy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${p.score} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isTop3 ? AppColors.neonGold : AppColors.textSecondary,
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

  // --- 4. 5 CATEGORY BUTTONS GRID ---
  Widget _buildFiveCategoryGrid() {
    final categories = [
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
            const SnackBar(content: Text('⚔️ 1 vs 1 Battle Arena is ready!')),
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
      children: categories.map((cat) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              borderRadius: 16,
              borderColor: (cat['color'] as Color).withOpacity(0.35),
              onTap: cat['onTap'] as VoidCallback,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    cat['icon'] as String,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['title'] as String,
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

  // --- 5. BOTTOM NAVIGATION BAR (Home, Quiz, Center Shield, Ranking, Profile) ---
  Widget _buildBottomNav() {
    return Container(
      height: 85,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home (Active Golden)
                _buildNavItem(icon: Icons.home_rounded, label: 'Home', isSelected: _currentNavIndex == 0, onTap: () => _onNavTap(0)),
                // 2. Quiz / Chapters
                _buildNavItem(icon: Icons.menu_book_rounded, label: 'Quiz', isSelected: _currentNavIndex == 1, onTap: () => _onNavTap(1)),
                // Space for center shield
                const SizedBox(width: 48),
                // 4. Ranking
                _buildNavItem(icon: Icons.emoji_events_rounded, label: 'Ranking', isSelected: _currentNavIndex == 3, onTap: () => _onNavTap(3)),
                // 5. Profile
                _buildNavItem(icon: Icons.person_rounded, label: 'Profile', isSelected: _currentNavIndex == 4, onTap: () => _onNavTap(4)),
              ],
            ),
          ),

          // 3. Center Golden Shield / Badge Button
          Positioned(
            top: -14,
            child: GestureDetector(
              onTap: _startDailyQuiz,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGold.withOpacity(0.6),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF0F172A),
                    size: 32,
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
    required bool isSelected,
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
            color: isSelected ? AppColors.neonGold : AppColors.textSecondary,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
              color: isSelected ? AppColors.neonGold : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
