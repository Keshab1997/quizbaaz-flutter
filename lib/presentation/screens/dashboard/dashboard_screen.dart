import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../../data/providers/rewards_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../admin/admin_dashboard_screen.dart';
import '../battle/battle_screen.dart';
import '../chapter_quiz/chapter_list_screen.dart';
import '../daily_quiz/daily_quiz_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../shop/shop_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
      context.read<UserProvider>().initialize();
      context.read<RewardsProvider>().initialize();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<UserProvider>().loadInitialData(),
      context.read<RewardsProvider>().initialize(),
    ]);
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChapterListScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
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
    setState(() => _isFemaleMascot = !_isFemaleMascot);
    context.read<UserProvider>().toggleGender();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final heroAsset = _isFemaleMascot ? AppAssets.heroGirl : AppAssets.heroBoy;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.neonCyan,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 132),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: 18),
                      _buildHeroCard(heroAsset),
                      const SizedBox(height: 14),
                      _buildStatStrip(user),
                      const SizedBox(height: 14),
                      _buildStreakCard(user),
                      const SizedBox(height: 26),
                      _buildSectionHeader(
                        eyebrow: 'PLAY YOUR WAY',
                        title: 'Quick actions',
                        actionLabel: 'See all',
                        onAction: () => _onNavTap(1),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(),
                      const SizedBox(height: 28),
                      _buildChampionCard(),
                      const SizedBox(height: 28),
                      _buildSectionHeader(
                        eyebrow: 'LIVE TODAY',
                        title: 'Leaderboard',
                        actionLabel: 'View full',
                        onAction: () => _onNavTap(2),
                      ),
                      const SizedBox(height: 12),
                      _buildLeaderboardPreview(),
                      const SizedBox(height: 12),
                      _buildAdminShortcut(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader(UserModel user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 365;
        return Row(
          children: [
            GestureDetector(
              onTap: _toggleMascotGender,
              child: Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonPurple.withValues(alpha: 0.36),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    _isFemaleMascot ? AppAssets.femaleAvatar : AppAssets.maleAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, ${user.fullName}  👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Ready to beat your best score?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildCurrencyPill(
              icon: Icons.monetization_on_rounded,
              value: '${user.coins}',
              color: AppColors.neonGold,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              _buildCurrencyPill(
                icon: Icons.diamond_rounded,
                value: '${user.gems}',
                color: AppColors.neonPurple,
              ),
            ],
            const SizedBox(width: 7),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                    size: 19,
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.neonRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyPill({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String heroAsset) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1C68), Color(0xFF162D67)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPurple.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -45,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonCyan.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -55,
              left: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonPink.withValues(alpha: 0.09),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 16, 16, 17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 126,
                    height: 182,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        heroAsset,
                        height: 181,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.neonGold,
                          size: 78,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.neonCyan.withValues(alpha: 0.32),
                            ),
                          ),
                          child: const Text(
                            'DAILY CHALLENGE',
                            style: TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          '10 questions.\nOne brilliant run.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _buildHeroMeta(Icons.timer_outlined, '03:20'),
                            const SizedBox(width: 6),
                            _buildHeroMeta(Icons.card_giftcard_rounded, '500 coins'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: NeonButton(
                            text: 'START QUIZ',
                            height: 43,
                            borderRadius: 14,
                            icon: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF191126),
                              size: 18,
                            ),
                            gradient: AppColors.goldGradient,
                            glowColor: AppColors.neonGold,
                            onPressed: _startDailyQuiz,
                          ),
                        ),
                      ],
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

  Widget _buildHeroMeta(IconData icon, String label) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.neonGold, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatStrip(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${user.dailyStreak}',
            label: 'day streak',
            color: AppColors.neonGold,
            detail: 'Keep it alive',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.track_changes_rounded,
            value: '72%',
            label: 'accuracy',
            color: AppColors.neonCyan,
            detail: 'Top 18% today',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String detail,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      borderRadius: 19,
      borderColor: color.withValues(alpha: 0.24),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(UserModel user) {
    final completed = user.dailyStreak.clamp(0, 7).toInt();
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      borderColor: AppColors.neonGold.withValues(alpha: 0.28),
      backgroundColor: const Color(0x54291E2D),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.fireGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGold.withValues(alpha: 0.22),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFF551F05),
                  size: 26,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR DAILY STREAK',
                      style: TextStyle(
                        color: AppColors.neonGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'One more day to unlock the bonus',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completed/7',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completed / 7,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonGold),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isDone = index < completed;
              final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
              return Column(
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.neonGold.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.045),
                      border: Border.all(
                        color: isDone
                            ? AppColors.neonGold.withValues(alpha: 0.75)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : Icons.circle_outlined,
                      size: 14,
                      color: isDone ? AppColors.neonGold : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String eyebrow,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_rounded, size: 13),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Chapters', Icons.menu_book_rounded, AppColors.neonCyan,
          () => _onNavTap(1)),
      _QuickAction('Practice', Icons.track_changes_rounded, AppColors.neonGreen,
          _startDailyQuiz),
      _QuickAction('Battle', Icons.bolt_rounded, AppColors.neonPink,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BattleScreen()))),
      _QuickAction('Rewards', Icons.card_giftcard_rounded, AppColors.neonGold,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()))),
      _QuickAction('Shop', Icons.storefront_rounded, AppColors.neonPurple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = actions[index];
          return GlassCard(
            width: 91,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            borderRadius: 19,
            borderColor: action.color.withValues(alpha: 0.26),
            onTap: action.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        action.color.withValues(alpha: 0.28),
                        action.color.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(color: action.color.withValues(alpha: 0.38)),
                  ),
                  child: Icon(action.icon, color: action.color, size: 23),
                ),
                const SizedBox(height: 8),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChampionCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF33240F), Color(0xFF251B33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGold.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 186,
          child: Stack(
            children: [
              Positioned(
                right: -22,
                bottom: -44,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonGold.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: -5,
                child: Image.asset(
                  AppAssets.championBoy,
                  height: 178,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.neonGold,
                    size: 90,
                  ),
                ),
              ),
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(148, 17, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: AppColors.neonGold, size: 17),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "YESTERDAY'S CHAMPION",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.neonGold,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 13),
                      Text(
                        'Rahul Das',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '96 pts  •  Rank #1',
                        style: TextStyle(
                          color: AppColors.neonGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(Icons.card_giftcard_rounded,
                              color: AppColors.neonPink, size: 15),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '500 coins + smartwatch',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    const players = <_Rank>[
      _Rank('1', 'Liam G.', '1200 pts', AppColors.neonGold, AppAssets.maleAvatar),
      _Rank('2', 'Sarah K.', '1180 pts', Color(0xFFC7D2E8), AppAssets.femaleAvatar),
      _Rank('3', 'Ben J.', '1150 pts', Color(0xFFDC9A67), AppAssets.maleAvatar),
      _Rank('4', 'Maya S.', '1125 pts', AppColors.textSecondary, AppAssets.femaleAvatar),
    ];

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      borderColor: AppColors.neonCyan.withValues(alpha: 0.22),
      child: Column(
        children: players
            .map(
              (player) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 25,
                      child: Text(
                        player.rank,
                        style: TextStyle(
                          color: player.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: player.color.withValues(alpha: 0.18),
                      backgroundImage: AssetImage(player.avatar),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      player.score,
                      style: TextStyle(
                        color: player.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAdminShortcut() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        },
        icon: const Icon(Icons.shield_rounded, size: 15, color: AppColors.textMuted),
        label: const Text(
          'Admin control panel',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 9),
        child: GlassCard(
          borderRadius: 27,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          borderColor: Colors.white.withValues(alpha: 0.14),
          backgroundColor: const Color(0xB3141A32),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Explore',
                  index: 1,
                ),
              ),
              SizedBox(
                width: 66,
                height: 60,
                child: GestureDetector(
                  onTap: _startDailyQuiz,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonGold.withValues(alpha: 0.38),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF211326),
                      size: 30,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Ranking',
                  index: 2,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _currentNavIndex == index;
    final color = selected ? AppColors.neonGold : AppColors.textMuted;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(this.title, this.icon, this.color, this.onTap);
}

class _Rank {
  final String rank;
  final String name;
  final String score;
  final Color color;
  final String avatar;

  const _Rank(this.rank, this.name, this.score, this.color, this.avatar);
}
