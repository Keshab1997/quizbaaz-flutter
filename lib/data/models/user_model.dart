import 'shop_item.dart';

enum UserGender { male, female }

class UserModel {
  final String userId;
  String username;
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

  void updateUsername(String newUsername) {
    username = newUsername; // Note: username field is final, we need to handle carefully
  }

  /// Set gender and update avatar accordingly.
  void setGender(UserGender newGender) {
    gender = newGender;
    avatarPath = newGender == UserGender.male
        ? 'assets/images/avatars/quizbaaz_avatar_boy.png'
        : 'assets/images/avatars/quizbaaz_avatar_girl.png';
  }

  // ----------------------------------------------------------------- JSON --

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'full_name': fullName,
        'avatar_path': avatarPath,
        'gender': gender.name,
        'coins': coins,
        'gems': gems,
        'daily_streak': dailyStreak,
        'is_guest': isGuest,
        'played_today_daily_quiz': playedTodayDailyQuiz,
        'inventory': inventory,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarPath: json['avatar_path'] as String? ??
          'assets/images/avatars/quizbaaz_avatar_boy.png',
      gender:
          (json['gender'] as String? ?? 'male') == 'male' ? UserGender.male : UserGender.female,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      dailyStreak: (json['daily_streak'] as num?)?.toInt() ?? 0,
      isGuest: json['is_guest'] as bool? ?? false,
      playedTodayDailyQuiz: json['played_today_daily_quiz'] as bool? ?? false,
      inventory: (json['inventory'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {},
    );
  }

  // -------------------------------------------------------------- Defaults --

  factory UserModel.defaultUser() {
    return UserModel(
      userId: 'usr_keshab_1997',
      username: 'Keshab1997',
      fullName: 'Keshab',
      avatarPath: 'assets/images/avatars/quizbaaz_avatar_boy.png', // intentional typo to match existing
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