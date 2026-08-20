class UserModel {
  final String userId;
  final String username;
  final String fullName;
  final String avatarPath;
  int coins;
  int gems;
  int dailyStreak;
  bool isGuest;
  bool playedTodayDailyQuiz;

  UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatarPath,
    this.coins = 500,
    this.gems = 20,
    this.dailyStreak = 6,
    this.isGuest = false,
    this.playedTodayDailyQuiz = false,
  });

  factory UserModel.defaultUser() {
    return UserModel(
      userId: 'usr_keshab_1997',
      username: 'Keshab1997',
      fullName: 'Keshab Sarkar',
      avatarPath: 'assets/images/characters/hero_boy_3d.png',
      coins: 1450,
      gems: 45,
      dailyStreak: 6,
      isGuest: false,
    );
  }

  factory UserModel.guestUser() {
    return UserModel(
      userId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      username: 'Guest Explorer',
      fullName: 'Guest Visitor',
      avatarPath: 'assets/images/avatars/user_boy_avatar.png',
      coins: 100,
      gems: 5,
      dailyStreak: 1,
      isGuest: true,
    );
  }
}
