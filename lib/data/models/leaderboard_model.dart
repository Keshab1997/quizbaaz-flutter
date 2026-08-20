class LeaderboardItem {
  final int rank;
  final String name;
  final String username;
  final String avatarPath;
  final int score;
  final double timeSeconds;
  final int streak;

  LeaderboardItem({
    required this.rank,
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.score,
    required this.timeSeconds,
    required this.streak,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      rank: json['rank'] ?? 1,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatarPath: json['avatar_path'] ?? '',
      score: json['score'] ?? 0,
      timeSeconds: (json['time_seconds'] as num?)?.toDouble() ?? 0.0,
      streak: json['streak'] ?? 1,
    );
  }
}
