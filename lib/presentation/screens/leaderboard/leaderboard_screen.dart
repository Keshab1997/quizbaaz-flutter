import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/models/champion_model.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../widgets/glass_card.dart';

class LeaderboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const LeaderboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
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
        title: const Text(
          'Hall of Fame & Rankings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            Tab(text: "YESTERDAY'S GIFTS 🎁"),
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

  bool _isNetworkAvatar(String avatar) =>
      avatar.startsWith('http://') || avatar.startsWith('https://');

  Widget _leaderboardAvatar(String avatar, double size, {Color? backgroundColor}) {
    final safeAvatar = avatar.isNotEmpty ? avatar : AppAssets.maleAvatar;
    final image = _isNetworkAvatar(safeAvatar)
        ? Image.network(
            safeAvatar,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.72),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.white10,
      ),
      child: image,
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
                  : 'No scores yet today',
              message: userProvider.isLoading
                  ? 'Fetching the latest results.'
                  : 'Play the Daily Quiz and your score appears here instantly.',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
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
              return _buildRankTile(item);
            },
          ),
          const SizedBox(height: 10),
          _buildYourPositionCard(userProvider),
        ],
      ),
      ),
    );
  }

  Widget _buildYourPositionCard(UserProvider userProvider) {
    if (!userProvider.hasPlayedDailyQuiz) {
      return GlassCard(
        borderRadius: 18,
        borderColor: Colors.white12,
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: AppColors.textMuted, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Play today\'s Daily Quiz to join the leaderboard! 🎯',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ),
      );
    }

    final rank = userProvider.playerRank ?? 1;
    final user = userProvider.user;
    final isTop3 = rank <= 3;

    return GlassCard(
      borderRadius: 18,
      borderColor: isTop3
          ? AppColors.neonGold.withValues(alpha: 0.6)
          : AppColors.neonCyan.withValues(alpha: 0.45),
      backgroundColor: isTop3 ? const Color(0x333F2E00) : AppColors.bgCardGlass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_pin_circle, size: 15, color: AppColors.neonCyan),
              SizedBox(width: 6),
              Text(
                'YOUR POSITION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonCyan,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Rank badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isTop3 ? AppColors.goldGradient : null,
                  color: isTop3 ? null : Colors.white10,
                  border: isTop3 ? null : Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isTop3 ? Colors.black : AppColors.neonCyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _leaderboardAvatar(user.effectiveAvatar, 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.neonCyan),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTop3 ? '🏆 You\'re on the podium!' : 'Keep going — beat the rank above!',
                      style: TextStyle(fontSize: 11, color: isTop3 ? AppColors.neonGold : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${userProvider.bestDailyScore} pts',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.neonGold),
                  ),
                  Text(
                    '${userProvider.bestDailyTime.toStringAsFixed(0)}s',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumView(List<LeaderboardItem> top3) {
    return GlassCard(
      borderRadius: 24,
      borderColor: AppColors.neonGold.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (top3.length > 1) _buildPodiumColumn(top3[1], 2, 90, const Color(0xFFC0C0C0)),
          // 1st Place
          if (top3.isNotEmpty) _buildPodiumColumn(top3[0], 1, 120, AppColors.neonGold),
          // 3rd Place
          if (top3.length > 2) _buildPodiumColumn(top3[2], 3, 75, const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(LeaderboardItem item, int rank, double height, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: rank == 1 ? 60 : 48,
          height: rank == 1 ? 60 : 48,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: _leaderboardAvatar(
            item.avatarPath.isNotEmpty ? item.avatarPath : AppAssets.heroBoy,
            rank == 1 ? 56 : 44,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (item.name.isNotEmpty ? item.name : item.username).split(' ').first,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          '${item.score} pts',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Column(
      children: [
        Icon(icon, size: 46, color: AppColors.textMuted),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildRankTile(LeaderboardItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 16,
        child: Row(
          children: [
            Text(
              '#${item.rank}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            _leaderboardAvatar(
              item.avatarPath.isNotEmpty ? item.avatarPath : AppAssets.maleAvatar,
              36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.isNotEmpty ? item.name : item.username,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '@${item.username}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.score} pts',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.neonGold),
                ),
                Text(
                  '${item.timeSeconds}s',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
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
            title: 'No champions published yet',
            message:
                "Yesterday's winners and their prizes show up here once the results are declared.",
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
            borderColor: isFirst ? AppColors.neonGold.withValues(alpha: 0.5) : Colors.white12,
            backgroundColor: isFirst ? const Color(0x333F2E00) : AppColors.bgCardGlass,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isFirst ? AppColors.goldGradient : null,
                    color: isFirst ? null : Colors.white10,
                  ),
                  child: Center(
                    child: Text(
                      '#${champ.rank}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isFirst ? Colors.black : Colors.white,
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
                          Text(
                            champ.name.isNotEmpty
                                ? champ.name
                                : champ.username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (champ.badgeTitle.isNotEmpty)
                            Text(
                              champ.badgeTitle,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.neonCyan),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (champ.giftName.isNotEmpty)
                        Row(
                        children: [
                          const Icon(Icons.card_giftcard, size: 14, color: AppColors.neonPink),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Reward: ${champ.giftName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neonGold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Score: ${champ.score} pts in ${champ.timeSeconds}s',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
