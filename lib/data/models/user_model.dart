import 'shop_item.dart';

enum UserGender { male, female }

class UserModel {
  final String userId;
  final String username;
  final String fullName;
  String avatarPath;
  UserGender gender;
  int coins;
  int gems;
  int dailyStreak;
  bool isGuest;
  bool playedTodayDailyQuiz;

  /// Owned shop items: itemId (ShopItemIds) -> quantity owned.
  Map<String, int> inventory;

  UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatarPath,
    this.gender = UserGender.male,
    this.coins = 1450,
    this.gems = 45,
    this.dailyStreak = 6,
    this.isGuest = false,
    this.playedTodayDailyQuiz = false,
    Map<String, int>? inventory,
  }) : inventory = inventory ?? {};

  /// How many units of [itemId] this user owns.
  int inventoryCount(String itemId) => inventory[itemId] ?? 0;

  void toggleGender() {
    if (gender == UserGender.male) {
      gender = UserGender.female;
      avatarPath = 'assets/images/avatars/quizbaaz_avatar_girl.png';
    } else {
      gender = UserGender.male;
      avatarPath = 'assets/images/avatars/quizbaaz_avatar_boy.png';
    }
  }

  factory UserModel.defaultUser() {
    return UserModel(
      userId: 'usr_keshab_1997',
      username: 'Keshab1997',
      fullName: 'Keshab',
      avatarPath: 'assets/images/avatars/quizbaaz_avatar_boy.png',
      gender: UserGender.male,
      coins: 1450,
      gems: 45,
      dailyStreak: 6,
      isGuest: false,
      inventory: {
        ShopItemIds.fiftyFifty: 3,
        ShopItemIds.freezeTime: 2,
        ShopItemIds.streakShield: 1,
      },
    );
  }

  factory UserModel.guestUser() {
    return UserModel(
      userId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      username: 'Guest Explorer',
      fullName: 'Guest User',
      avatarPath: 'assets/images/avatars/quizbaaz_avatar_boy.png',
      gender: UserGender.male,
      coins: 100,
      gems: 5,
      dailyStreak: 1,
      isGuest: true,
      inventory: {
        ShopItemIds.fiftyFifty: 1,
        ShopItemIds.freezeTime: 1,
      },
    );
  }
}
