/// Currency used to buy a shop item.
enum ShopCurrency { coins, gems }

/// A purchasable item in the Power-Up Shop.
///
/// - Consumables (lifelines, shields) grant [quantity] units per purchase and
///   can be bought repeatedly.
/// - Cosmetics ([isCosmetic] = true) are unlocked once and can't be bought again.
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final ShopCurrency currency;

  /// How many units one purchase grants (e.g. 3 x 50-50 lifelines).
  final int quantity;

  /// Cosmetics are one-time unlocks (owned = 1) instead of stackable items.
  final bool isCosmetic;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.currency,
    this.quantity = 1,
    this.isCosmetic = false,
  });

  String get currencyLabel => currency == ShopCurrency.coins ? 'Coins' : 'Gems';

  bool get costsCoins => currency == ShopCurrency.coins;
}

/// Central, stable ids for every item sold in the shop.
/// Used to key the user's inventory so purchases survive restarts.
class ShopItemIds {
  static const String fiftyFifty = 'fifty_fifty';
  static const String freezeTime = 'freeze_time';
  static const String streakShield = 'streak_shield';
  static const String vipAvatar = 'vip_avatar';
}

/// The full shop catalogue. Add new items here and they automatically appear
/// in the Shop screen.
class ShopCatalog {
  static const List<ShopItem> items = [
    ShopItem(
      id: ShopItemIds.fiftyFifty,
      name: '50-50 Lifeline',
      description: 'Removes 2 wrong options during a quiz',
      cost: 150,
      currency: ShopCurrency.coins,
      quantity: 3,
    ),
    ShopItem(
      id: ShopItemIds.freezeTime,
      name: '+10s Freeze Time',
      description: 'Adds 10 extra seconds to the quiz timer',
      cost: 200,
      currency: ShopCurrency.coins,
      quantity: 2,
    ),
    ShopItem(
      id: ShopItemIds.streakShield,
      name: 'Streak Freeze Shield',
      description: 'Protects your streak if you miss a day',
      cost: 20,
      currency: ShopCurrency.gems,
      quantity: 1,
    ),
    ShopItem(
      id: ShopItemIds.vipAvatar,
      name: 'VIP Golden Avatar',
      description: 'Unlocks a glowing 3D VIP avatar',
      cost: 50,
      currency: ShopCurrency.gems,
      quantity: 1,
      isCosmetic: true,
    ),
  ];
}
