import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../data/models/champion_model.dart';
import 'glass_card.dart';

class ChampionPodiumWidget extends StatelessWidget {
  final ChampionModel? champion;
  final VoidCallback? onViewProfile;

  const ChampionPodiumWidget({
    super.key,
    this.champion,
    this.onViewProfile,
  });

  bool _isNetworkAvatar(String avatar) =>
      avatar.startsWith('http://') || avatar.startsWith('https://');

  Widget _championAvatar(String avatar) {
    final safeAvatar = avatar.isNotEmpty ? avatar : AppAssets.championBoy;
    if (_isNetworkAvatar(safeAvatar)) {
      return Image.network(
        safeAvatar,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.person, size: 48, color: AppColors.neonGold),
        ),
      );
    }
    return Image.asset(
      safeAvatar,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.person, size: 48, color: AppColors.neonGold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final champ = champion;

    // No champion published yet -> honest empty state, never a fake winner.
    if (champ == null) {
      return GlassCard(
        borderColor: AppColors.neonGold.withValues(alpha: 0.22),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined,
                color: AppColors.textMuted, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No champion has been crowned yet. Win a daily quiz to be the first!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      borderColor: AppColors.neonGold.withValues(alpha: 0.4),
      backgroundColor: const Color(0x33281E48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          "YESTERDAY'S #1 WINNER",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (onViewProfile != null)
                GestureDetector(
                  onTap: onViewProfile,
                  child: const Text(
                    'View History >',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 3D Character standing on podium
              Container(
                width: 85,
                height: 95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonPurple.withValues(alpha: 0.3),
                      AppColors.neonCyan.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _championAvatar(champ.avatarPath),
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      champ.name.isNotEmpty ? champ.name : champ.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      champ.username,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (champ.giftName.isNotEmpty)
                      Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.card_giftcard, size: 14, color: AppColors.neonPink),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Won: ${champ.giftName}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neonGold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}
