import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/shop_item.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/purchase_celebration.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  IconData _iconFor(String itemId) {
    switch (itemId) {
      case ShopItemIds.fiftyFifty:
        return Icons.filter_2;
      case ShopItemIds.freezeTime:
        return Icons.ac_unit;
      case ShopItemIds.streakShield:
        return Icons.shield_moon;
      case ShopItemIds.vipAvatar:
        return Icons.workspace_premium;
      default:
        return Icons.card_giftcard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Power-Up Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Balance Bar
          GlassCard(
            borderRadius: 20,
            borderColor: AppColors.neonCyan.withValues(alpha: 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.neonGold, size: 24),
                    const SizedBox(width: 8),
                    Text('${user.coins} Coins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonGold)),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.white24),
                Row(
                  children: [
                    const Icon(Icons.diamond, color: AppColors.neonPurple, size: 24),
                    const SizedBox(width: 8),
                    Text('${user.gems} Gems', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'AVAILABLE POWER-UPS & ITEMS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lifelines you buy appear instantly in the quiz.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          ...ShopCatalog.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _ShopItemCard(
                item: item,
                icon: _iconFor(item.id),
                owned: userProvider.inventoryCount(item.id),
                affordable: userProvider.canAfford(item),
                onBuy: () => _handleBuy(context, userProvider, item),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _handleBuy(BuildContext context, UserProvider userProvider, ShopItem item) {
    final result = userProvider.purchaseItem(item);

    switch (result) {
      case PurchaseStatus.success:
        // Instant 3D-character celebration instead of the slow SnackBar.
        PurchaseCelebration.show(
          context,
          itemName: item.name,
          subtitle: item.isCosmetic
              ? 'Unlocked forever!'
              : '+${item.quantity} added to your inventory',
          characterAsset: AppAssets.quizChampion,
          itemIcon: _iconFor(item.id),
          accent: item.costsCoins ? AppColors.neonGold : AppColors.neonPurple,
        );
        break;
      case PurchaseStatus.alreadyOwned:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1200),
            content: Text('You already own this item!'),
          ),
        );
        break;
      case PurchaseStatus.insufficientFunds:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1200),
            content: Text('Not enough ${item.currencyLabel}! Earn more by playing quizzes.'),
            backgroundColor: Colors.red.shade800,
          ),
        );
        break;
    }
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final IconData icon;
  final int owned;
  final bool affordable;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.icon,
    required this.owned,
    required this.affordable,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final isGems = !item.costsCoins;

    final Color accent = isGems ? AppColors.neonPurple : AppColors.neonGold;

    return GlassCard(
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(item.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  _ownedLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: owned > 0 ? AppColors.neonCyan : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildButton(accent),
        ],
      ),
    );
  }

  String _ownedLabel() {
    if (item.isCosmetic) {
      return owned > 0 ? 'OWNED ✓' : 'NOT OWNED';
    }
    return 'OWNED: x$owned';
  }

  Widget _buildButton(Color accent) {
    // Cosmetic already owned -> show a static owned badge.
    if (item.isCosmetic && owned > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
        ),
        child: const Text(
          'OWNED ✓',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neonCyan),
        ),
      );
    }

    final Color bg = affordable ? accent : Colors.white.withValues(alpha: 0.08);
    final Color fg = affordable
        ? (item.costsCoins ? Colors.black : Colors.white)
        : AppColors.textSecondary;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
        disabledForegroundColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      // Still tappable when unaffordable so the user gets a helpful
      // "not enough coins/gems" message instead of a dead button.
      onPressed: onBuy,
      child: Text(
        '${item.cost} ${item.currencyLabel}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
