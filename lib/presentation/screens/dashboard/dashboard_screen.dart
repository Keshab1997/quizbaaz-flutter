import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/champion_model.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/user_stats.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../../data/providers/rewards_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/name_effect_text.dart';
import '../../widgets/neon_button.dart';
import '../admin/admin_dashboard_screen.dart';
import '../battle/battle_screen.dart';
import '../chapter_quiz/chapter_list_screen.dart';
import '../daily_quiz/daily_quiz_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../history/quiz_history_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_screen.dart';
import '../shop/shop_screen.dart';
import '../../widgets/aura_avatar.dart';
import '../../widgets/cached_avatar.dart';
import '../../widgets/daily_winner_celebration_dialog.dart';
import '../../widgets/streak_reset_dialog.dart';
import '../../../l10n/app_strings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  final bool _isFemaleMascot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = context.read<UserProvider>();
      await userProvider.initialize();
      if (!mounted) return;
      context
          .read<RewardsProvider>()
          .initialize(userId: userProvider.user.userId);

      // Check and claim yesterday's daily leaderboard rewards!
      final reward = await userProvider.checkAndClaimDailyLeaderboardRewards();
      if (mounted && reward != null) {
        DailyWinnerCelebrationDialog.show(context, reward);
      } else if (mounted) {
        // Check if daily streak was reset and warn player / offer Streak Shield recovery!
        final streakReset = userProvider.checkStreakResetWarning();
        if (streakReset != null) {
          StreakResetDialog.show(context, streakReset);
        }
      }
    });
  }

  Future<void> _refresh() async {
    final userProvider = context.read<UserProvider>();
    await Future.wait([
      userProvider.refreshRankings(force: true),
      context
          .read<RewardsProvider>()
          .initialize(userId: userProvider.user.userId),
    ]);
  }

  /// Opens a tab and restores the Home highlight once the user comes back,
  /// so the bottom bar never lies about where you are.
  Future<void> _openTab(int index, Widget screen) async {
    setState(() => _currentNavIndex = index);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() => _currentNavIndex = 0);
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentNavIndex = 0);
        break;
      case 1:
        _openTab(1, const ChapterListScreen());
        break;
      case 2:
        _openTab(2, const LeaderboardScreen());
        break;
      case 3:
        _openTab(3, const ProfileScreen());
        break;
    }
  }

  /// Time-aware greeting instead of a fixed "Good morning".
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return S.greetStillAwake;
    if (hour < 12) return S.greetMorning;
    if (hour < 17) return S.greetAfternoon;
    if (hour < 21) return S.greetEvening;
    return S.greetNight;
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
                      _buildHeader(user, userProvider),
                      const SizedBox(height: 18),
                      _buildHeroCard(heroAsset, userProvider),
                      const SizedBox(height: 14),
                      _buildStatStrip(user, userProvider),
                      const SizedBox(height: 14),
                      _buildStreakCard(user, userProvider),
                      const SizedBox(height: 26),
                      _buildSectionHeader(
                        eyebrow: S.dashPlayYourWay,
                        title: S.dashQuickActions,
                        actionLabel: S.dashSeeAll,
                        onAction: () => _onNavTap(1),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(),
                      const SizedBox(height: 28),
                      _buildChampionCard(userProvider),
                      const SizedBox(height: 28),
                      _buildSectionHeader(
                        eyebrow: S.dashLiveToday,
                        title: S.dashLeaderboard,
                        actionLabel: S.dashViewFull,
                        onAction: () => _onNavTap(2),
                      ),
                      const SizedBox(height: 12),
                      _buildLeaderboardPreview(userProvider),
                      const SizedBox(height: 12),
                      if (userProvider.isAdmin) _buildAdminShortcut(),
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

  bool _isNetworkAvatar(String avatar) =>
      avatar.startsWith('http://') || avatar.startsWith('https://');

  Widget _avatarImage(
    String avatar, {
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    double? width,
    double? height,
    IconData fallbackIcon = Icons.person_rounded,
    double fallbackSize = 28,
  }) {
    if (_isNetworkAvatar(avatar)) {
      return CachedAvatar(
        url: avatar,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        fallbackIcon: fallbackIcon,
        fallbackIconColor: Colors.white,
        fallbackIconSize: fallbackSize,
      );
    }

    return Image.asset(
      avatar,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Icon(
        fallbackIcon,
        color: Colors.white,
        size: fallbackSize,
      ),
    );
  }

  Widget _buildHeader(UserModel user, UserProvider userProvider) {
    return Row(
      children: [
        AuraAvatar(
          url: user.effectiveAvatar,
          size: 68,
          fallbackAsset: user.avatarPath,
          onTap: () => _openTab(3, const ProfileScreen()),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MarqueeText(
                '$_greeting  👋',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              _MarqueeText(
                user.fullName.isNotEmpty ? user.fullName : user.username,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
                effectId: user.nameEffect,
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
        const SizedBox(width: 6),
        _buildCurrencyPill(
          icon: Icons.diamond_rounded,
          value: '${user.gems}',
          color: AppColors.neonPurple,
        ),
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

  Widget _buildHeroCard(String heroAsset, UserProvider userProvider) {
    final config = userProvider.config;
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
                        Text(
                          '${config.dailyQuestionCount} questions.\nOne brilliant run.',
                          style: const TextStyle(
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
                            _buildHeroMeta(
                                Icons.timer_outlined, config.dailyDurationLabel),
                            const SizedBox(width: 6),
                            _buildHeroMeta(Icons.card_giftcard_rounded,
                                'up to ${config.dailyMaxCoins} coins'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: NeonButton(
                            text: userProvider.user.playedTodayDailyQuiz
                                ? 'PLAY AGAIN'
                                : 'START QUIZ',
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

  Widget _buildStatStrip(UserModel user, UserProvider userProvider) {
    final UserStats stats = userProvider.stats;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${user.dailyStreak}',
            label: S.dashDayStreak,
            color: AppColors.neonGold,
            detail: user.dailyStreak > 0
                ? 'Keep it alive'
                : 'Play today to start',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.track_changes_rounded,
            value: stats.accuracyLabel,
            label: S.dashAccuracyShort,
            color: AppColors.neonCyan,
            detail: stats.hasData
                ? (userProvider.percentileLabel ??
                    '${stats.totalAnswered} questions answered')
                : 'No quiz played yet',
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

  Widget _buildStreakCard(UserModel user, UserProvider userProvider) {
    final goal = userProvider.config.streakGoalDays;
    final completed = user.dailyStreak.clamp(0, goal).toInt();
    final remaining = goal - completed;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR DAILY STREAK',
                      style: TextStyle(
                        color: AppColors.neonGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      remaining <= 0
                          ? 'Streak goal complete — bonus unlocked!'
                          : '$remaining more day${remaining == 1 ? '' : 's'} to unlock the bonus',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completed/$goal',
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
              value: goal == 0 ? 0.0 : completed / goal,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonGold),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(goal, (index) {
              final isDone = index < completed;
              final label = _weekdayInitials[index % _weekdayInitials.length];
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
      _QuickAction(S.dashChapters, Icons.menu_book_rounded, AppColors.neonCyan,
          () => _onNavTap(1)),
      _QuickAction(S.dashHistory, Icons.history_rounded, AppColors.neonPurple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizHistoryScreen()))),
      _QuickAction(S.dashBattle, Icons.bolt_rounded, AppColors.neonPink,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BattleScreen()))),
      _QuickAction(S.dashRewards, Icons.card_giftcard_rounded, AppColors.neonGold,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()))),
      _QuickAction(S.dashShop, Icons.storefront_rounded, AppColors.neonPurple,
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

  /// Yesterday's champion — real data from Hive/Firestore, or an honest
  /// empty state while nobody has been crowned yet.
  Widget _buildChampionCard(UserProvider userProvider) {
    final ChampionModel? champ = userProvider.yesterdayTopChampion;

    if (champ == null) {
      return GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        borderColor: AppColors.neonGold.withValues(alpha: 0.22),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonGold.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.neonGold, size: 24),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No champion yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Yesterday's winner appears here once results are in.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
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

    final championAvatar =
        champ.avatarPath.isNotEmpty ? champ.avatarPath : AppAssets.maleAvatar;
    final prizeLabel = _championPrizeLabel(champ);

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
                child: _avatarImage(
                  championAvatar,
                  height: 178,
                  fit: BoxFit.contain,
                  fallbackIcon: Icons.emoji_events_rounded,
                  fallbackSize: 90,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(148, 17, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
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
                      const SizedBox(height: 13),
                      NameEffectText(
                        champ.name.isNotEmpty ? champ.name : champ.username,
                        effectId: champ.nameEffect,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${champ.score} pts  •  Rank #${champ.rank}',
                        style: const TextStyle(
                          color: AppColors.neonGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (prizeLabel != null)
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard_rounded,
                                color: AppColors.neonPink, size: 15),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                prizeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
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

  /// Builds the prize line only from what the backend actually sent.
  String? _championPrizeLabel(ChampionModel champ) {
    final parts = <String>[];
    if (champ.bonusCoins > 0) parts.add('${champ.bonusCoins} coins');
    if (champ.giftName.isNotEmpty) parts.add(champ.giftName);
    return parts.isEmpty ? null : parts.join(' + ');
  }

  /// Live top-4 straight from the Hive-cached leaderboard.
  Widget _buildLeaderboardPreview(UserProvider userProvider) {
    final List<LeaderboardItem> players =
        userProvider.leaderboard.take(4).toList();

    if (players.isEmpty) {
      return GlassCard(
        borderRadius: 22,
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        borderColor: AppColors.neonCyan.withValues(alpha: 0.18),
        child: Row(
          children: [
            const Icon(Icons.leaderboard_rounded,
                color: AppColors.textMuted, size: 22),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                userProvider.isLoading
                    ? 'Loading today\'s ranking…'
                    : 'No scores today yet — be the first on the board!',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      borderColor: AppColors.neonCyan.withValues(alpha: 0.22),
      child: Column(
        children: players.map((player) {
          final color = _rankColor(player.rank);
          final avatar = player.avatarPath.isNotEmpty
              ? player.avatarPath
              : AppAssets.maleAvatar;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 25,
                  child: Text(
                    '${player.rank}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.18),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _avatarImage(avatar, alignment: Alignment.topCenter),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NameEffectText(
                    player.name.isNotEmpty ? player.name : player.username,
                    effectId: player.nameEffect,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${player.score} pts',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.neonGold;
      case 2:
        return const Color(0xFFC7D2E8);
      case 3:
        return const Color(0xFFDC9A67);
      default:
        return AppColors.textSecondary;
    }
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
                  label: S.navHome,
                  index: 0,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.menu_book_rounded,
                  label: S.navExplore,
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
                  label: S.navRanking,
                  index: 2,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_rounded,
                  label: S.navProfile,
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
/// Labels for the streak ring (repeats when the goal is longer than a week).
const List<String> _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class _QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(this.title, this.icon, this.color, this.onTap);
}

/// A single-line text that scrolls horizontally (marquee) when it overflows
/// its available width, so long greetings and names stay fully readable on
/// narrow screens instead of being truncated with an ellipsis.
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final String? effectId;

  const _MarqueeText(
    this.text, {
    required this.style,
    this.effectId,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// How long one full scroll loop takes.
  static const Duration _scrollDuration = Duration(seconds: 6);

  /// Horizontal gap between the two copies of the text that make the scroll
  /// loop look seamless.
  static const double _gap = 48;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _scrollDuration,
    );
  }

  @override
  void didUpdateWidget(_MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        final textWidth = painter.width;
        final textHeight = painter.height;
        final overflow = textWidth > constraints.maxWidth;

        // Drive the animation controller outside of build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (overflow && !_controller.isAnimating) {
            _controller.repeat();
          } else if (!overflow && _controller.isAnimating) {
            _controller.stop();
            _controller.reset();
          }
        });

        if (!overflow) {
          return SizedBox(
            height: textHeight,
            child: NameEffectText(
              widget.text,
              effectId: widget.effectId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.style,
            ),
          );
        }

        return SizedBox(
          height: textHeight,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final dx = -_controller.value * (textWidth + _gap);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NameEffectText(
                          widget.text,
                          effectId: widget.effectId,
                          maxLines: 1,
                          style: widget.style,
                        ),
                        const SizedBox(width: _gap),
                        NameEffectText(
                          widget.text,
                          effectId: widget.effectId,
                          maxLines: 1,
                          style: widget.style,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

