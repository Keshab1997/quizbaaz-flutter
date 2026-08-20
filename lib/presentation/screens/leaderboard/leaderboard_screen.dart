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
      backgroundColor: AppColors.bgDark,
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
          _buildTodayLeaderboardTab(leaderboard),
          _buildYesterdayWinnersTab(champions),
        ],
      ),
    );
  }

  Widget _buildTodayLeaderboardTab(List<LeaderboardItem> list) {
    if (list.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
    }

    final top3 = list.take(3).toList();
    final rest = list.skip(3).toList();

    return SingleChildScrollView(
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
        CircleAvatar(
          radius: rank == 1 ? 30 : 24,
          backgroundColor: color,
          child: CircleAvatar(
            radius: rank == 1 ? 28 : 22,
            backgroundImage: AssetImage(
              item.avatarPath.isNotEmpty ? item.avatarPath : AppAssets.heroBoy,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.name.split(' ').first,
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
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(
                item.avatarPath.isNotEmpty ? item.avatarPath : AppAssets.maleAvatar,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    item.username,
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
      return const Center(child: Text('No champion archive found'));
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
                            champ.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            champ.badgeTitle,
                            style: const TextStyle(fontSize: 11, color: AppColors.neonCyan),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
