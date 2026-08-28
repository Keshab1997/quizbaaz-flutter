import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/models/champion_model.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/name_effect_text.dart';
import '../../widgets/cached_avatar.dart';
import '../../../l10n/app_strings.dart';

class LeaderboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const LeaderboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<_ConfettiParticle> _confetti = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
    _generateConfetti();
  }

  void _generateConfetti() {
    for (int i = 0; i < 30; i++) {
      _confetti.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        color: [
          AppColors.neonGold,
          AppColors.neonOrange,
          AppColors.neonCyan,
          AppColors.neonPurple,
          AppColors.neonPink,
        ][_random.nextInt(5)],
        size: _random.nextDouble() * 6 + 3,
        speed: _random.nextDouble() * 0.5 + 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _isNetworkAvatar(String avatar) =>
      avatar.startsWith('http://') || avatar.startsWith('https://');

  Widget _leaderboardAvatar(String avatar, double size, {Color? borderColor}) {
    final safeAvatar = avatar.isNotEmpty ? avatar : AppAssets.maleAvatar;
    final image = _isNetworkAvatar(safeAvatar)
        ? CachedAvatar(
            url: safeAvatar,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.72),
            fallbackIcon: Icons.person_rounded,
            fallbackIconColor: Colors.white,
          )
        : Image.asset(
            safeAvatar,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.72),
            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white),
          );

    return Container(
      width: size,
      height: size,
      padding: borderColor != null ? EdgeInsets.all(borderColor == AppColors.neonGold ? 3 : 2) : null,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderColor == AppColors.neonGold ? 3 : 2)
            : null,
        gradient: borderColor == AppColors.neonGold
            ? const LinearGradient(colors: [AppColors.neonGold, AppColors.neonOrange])
            : null,
        boxShadow: borderColor != null
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final leaderboard = userProvider.leaderboard;
    final champions = userProvider.champions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          S.lbTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonGold,
          indicatorWeight: 3,
          labelColor: AppColors.neonGold,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "TODAY'S LIVE RANK"),
            Tab(text: "YESTERDAY'S WINNERS 🎁"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayLeaderboardTab(leaderboard, userProvider),
          _buildYesterdayWinnersTab(champions),
        ],
      ),
    );
  }

  Widget _buildTodayLeaderboardTab(
      List<LeaderboardItem> list, UserProvider userProvider) {
    if (list.isEmpty) {
      return RefreshIndicator(
        color: AppColors.neonCyan,
        onRefresh: () => userProvider.refreshRankings(force: true),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            _buildEmptyState(
              icon: Icons.leaderboard_rounded,
              title: userProvider.isLoading
                  ? 'Loading today\'s ranking…'
                  : S.lbNoScoresToday,
              message: userProvider.isLoading
                  ? S.lbFetching
                  : S.lbNoScoresBody,
            ),
          ],
        ),
      );
    }

    final top3 = list.take(3).toList();
    final rest = list.skip(3).toList();

    return RefreshIndicator(
      color: AppColors.neonCyan,
      onRefresh: () => userProvider.refreshRankings(force: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          children: [
            // Confetti Background
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(particles: _confetti),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Header
                  _buildLeaderboardHeader(),
                  const SizedBox(height: 16),
                  
                  // Top 3 Podium
                  _buildPodiumView(top3),
                  const SizedBox(height: 20),

                  // Rest of the ranks
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rest.length,
                    itemBuilder: (context, index) {
                      final item = rest[index];
                      return _buildRankTile(item, index + 4);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildYourPositionCard(userProvider),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonGold.withValues(alpha: 0.2),
            AppColors.neonOrange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S LIVE RANKING",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonGold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Top players competing right now! 🏆',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.neonOrange,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourPositionCard(UserProvider userProvider) {
    if (!userProvider.hasPlayedDailyQuiz) {
      return const GlassCard(
        borderRadius: 18,
        borderColor: Colors.white12,
        child: Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.neonGold, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "JOIN THE RACE!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonGold,
                    ),
                  ),
                  Text(
                    'Play today\'s Daily Quiz to join the leaderboard! 🎯',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final rank = userProvider.playerRank ?? 1;
    final user = userProvider.user;
    final isTop3 = rank <= 3;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isTop3 ? _pulseAnimation.value : 1.0,
          child: GlassCard(
            borderRadius: 20,
            borderColor: isTop3
                ? AppColors.neonGold.withValues(alpha: 0.7)
                : AppColors.neonCyan.withValues(alpha: 0.5),
            backgroundColor: isTop3 ? const Color(0x333F2E00) : AppColors.bgCardGlass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isTop3 ? AppColors.goldGradient : null,
                        color: isTop3 ? null : AppColors.neonCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTop3 ? Icons.star_rounded : Icons.person_pin_rounded,
                            size: 16,
                            color: isTop3 ? Colors.black : AppColors.neonCyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isTop3 ? '🏆 ON THE PODIUM!' : 'YOUR POSITION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isTop3 ? Colors.black : AppColors.neonCyan,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isTop3)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColors.fireGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonOrange.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Rank badge with glow
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isTop3 ? AppColors.goldGradient : null,
                        color: isTop3 ? null : Colors.white10,
                        border: isTop3 ? null : Border.all(color: AppColors.neonCyan, width: 2),
                        boxShadow: isTop3
                            ? [
                                BoxShadow(
                                  color: AppColors.neonGold.withValues(alpha: 0.6),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isTop3 ? Colors.black : AppColors.neonCyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _leaderboardAvatar(user.effectiveAvatar, 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: NameEffectText(
                                  user.fullName,
                                  effectId: user.nameEffect,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: AppColors.cyanGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  S.you,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isTop3 ? Icons.celebration_rounded : Icons.trending_up_rounded,
                                size: 14,
                                color: isTop3 ? AppColors.neonGold : AppColors.neonGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isTop3 ? 'Amazing! You\'re a champion!' : 'Keep going — you\'re doing great!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isTop3 ? AppColors.neonGold : AppColors.neonGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${userProvider.bestDailyScore}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.neonGold,
                            ),
                          ),
                        ),
                        const Text(
                          'pts',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodiumView(List<LeaderboardItem> top3) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Glow effect behind podium
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.2,
              colors: [
                AppColors.neonGold.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        GlassCard(
          borderRadius: 24,
          borderColor: AppColors.neonGold.withValues(alpha: 0.4),
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              if (top3.length > 1) _buildPodiumColumn(top3[1], 2, 100, const Color(0xFFC0C0C0)),
              // 1st Place
              if (top3.isNotEmpty) _buildPodiumColumn(top3[0], 1, 130, AppColors.neonGold),
              // 3rd Place
              if (top3.length > 2) _buildPodiumColumn(top3[2], 3, 85, const Color(0xFFCD7F32)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumColumn(LeaderboardItem item, int rank, double height, Color color) {
    final isFirst = rank == 1;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isFirst ? _pulseAnimation.value : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crown for 1st place
              if (isFirst)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonGold.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Text('👑', style: TextStyle(fontSize: 20)),
                ),
              if (isFirst) const SizedBox(height: 4),
              
              // Avatar with ring
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.all(isFirst ? 4 : 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isFirst 
                                ? [AppColors.neonGold, AppColors.neonOrange]
                                : [color, color.withValues(alpha: 0.7)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: isFirst ? 16 : 8,
                              spreadRadius: isFirst ? 2 : 1,
                            ),
                          ],
                        ),
                        child: _leaderboardAvatar(
                          item.avatarPath.isNotEmpty ? item.avatarPath : AppAssets.heroBoy,
                          isFirst ? 64 : 50,
                        ),
                      );
                    },
                  ),
                  // Rank badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: rank == 1 ? 12 : 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Name with glow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (item.name.isNotEmpty ? item.name : item.username).split(' ').first,
                  style: TextStyle(
                    fontSize: rank == 1 ? 13 : 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Score
              Row(
                children: [
                  Icon(Icons.stars_rounded, size: 14, color: color),
                  const SizedBox(width: 2),
                  Text(
                    '${item.score}',
                    style: TextStyle(
                      fontSize: rank == 1 ? 15 : 12,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Podium stand
              Container(
                width: 75,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      if (isFirst)
                        const Text('👑', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.neonGold.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(icon, size: 50, color: AppColors.neonGold),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRankTile(LeaderboardItem item, int rank) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 16,
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: Row(
          children: [
            // Rank number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            _leaderboardAvatar(
              item.avatarPath.isNotEmpty ? item.avatarPath : AppAssets.maleAvatar,
              40,
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NameEffectText(
                    item.name.isNotEmpty ? item.name : item.username,
                    effectId: item.nameEffect,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${item.timeSeconds}s',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonGold.withValues(alpha: 0.3),
                    AppColors.neonOrange.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 14, color: AppColors.neonGold),
                  const SizedBox(width: 4),
                  Text(
                    '${item.score}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonGold,
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

  Widget _buildYesterdayWinnersTab(List<ChampionModel> champions) {
    if (champions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          _buildEmptyState(
            icon: Icons.card_giftcard_rounded,
            title: S.lbNoChampions,
            message: "Yesterday's winners and their prizes show up here once the results are declared.",
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: champions.length,
      itemBuilder: (context, index) {
        final champ = champions[index];
        final isFirst = champ.rank == 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: GlassCard(
            borderRadius: 20,
            borderColor: isFirst 
                ? AppColors.neonGold.withValues(alpha: 0.6)
                : Colors.white12,
            backgroundColor: isFirst 
                ? const Color(0x333F2E00)
                : AppColors.bgCardGlass,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isFirst ? AppColors.goldGradient : null,
                    color: isFirst ? null : Colors.white10,
                    boxShadow: isFirst
                        ? [
                            BoxShadow(
                              color: AppColors.neonGold.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isFirst
                        ? const Text('👑', style: TextStyle(fontSize: 22))
                        : Text(
                            '#${champ.rank}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              champ.name.isNotEmpty ? champ.name : champ.username,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isFirst ? AppColors.neonGold : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (champ.giftName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.neonPink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.card_giftcard, size: 12, color: AppColors.neonPink),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  champ.giftName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neonPink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        S.lbChampScore(score: champ.score, time: champ.timeSeconds),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isFirst)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Confetti particle class
class _ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double speed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
  });
}

// Confetti painter
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
