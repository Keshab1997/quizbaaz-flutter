class ChampionModel {
  final int rank;
  final String userId;
  final String name;
  final String username;
  final String avatarPath;
  final int score;
  final double timeSeconds;
  final String giftName;
  final String giftIcon;
  final int bonusCoins;
  final String badgeTitle;

  ChampionModel({
    required this.rank,
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.score,
    required this.timeSeconds,
    required this.giftName,
    required this.giftIcon,
    required this.bonusCoins,
    required this.badgeTitle,
  });

  factory ChampionModel.fromJson(Map<String, dynamic> json) {
    return ChampionModel(
      rank: json['rank'] ?? 1,
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatarPath: json['avatar_path'] ?? '',
      score: json['score'] ?? 0,
      timeSeconds: (json['time_seconds'] as num?)?.toDouble() ?? 0.0,
      giftName: json['gift_name'] ?? '',
      giftIcon: json['gift_icon'] ?? '',
      bonusCoins: json['bonus_coins'] ?? 0,
      badgeTitle: json['badge_title'] ?? '',
    );
  }
}
