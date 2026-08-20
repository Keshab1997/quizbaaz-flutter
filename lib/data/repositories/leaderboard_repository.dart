import '../models/champion_model.dart';
import '../models/leaderboard_model.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';

/// Hive-first access to ranking data.
///
/// Reading is always instant: the cached rows in Hive are returned straight
/// away, then Firestore is queried in the background and the cache refreshed.
/// There is no bundled JSON fallback any more — if there is no data, the
/// screens show a real empty state instead of invented players.
class LeaderboardRepository {
  /// Cached leaderboard rows (may be empty).
  List<LeaderboardItem> cachedLeaderboard() {
    return HiveService.cacheGetList(HiveService.cacheLeaderboard)
        .map(LeaderboardItem.fromJson)
        .toList();
  }

  /// Cached champions (may be empty).
  List<ChampionModel> cachedChampions() {
    return HiveService.cacheGetList(HiveService.cacheChampions)
        .map(ChampionModel.fromJson)
        .toList();
  }

  /// True when the cached leaderboard is still fresh enough to skip a fetch.
  bool isLeaderboardFresh(Duration ttl) =>
      HiveService.isCacheFresh(HiveService.cacheLeaderboard, ttl);

  bool areChampionsFresh(Duration ttl) =>
      HiveService.isCacheFresh(HiveService.cacheChampions, ttl);

  /// Pulls today's leaderboard from Firestore into the Hive cache.
  Future<List<LeaderboardItem>> refreshLeaderboard({int limit = 50}) async {
    final rows = await SyncService.pullLeaderboard(limit: limit);
    if (rows.isEmpty) return cachedLeaderboard();
    return rows.map(LeaderboardItem.fromJson).toList();
  }

  /// Pulls yesterday's champions from Firestore into the Hive cache.
  Future<List<ChampionModel>> refreshChampions({int limit = 10}) async {
    final rows = await SyncService.pullChampions(limit: limit);
    if (rows.isEmpty) return cachedChampions();
    return rows.map(ChampionModel.fromJson).toList();
  }

  /// When the ranking data was last downloaded, or null.
  DateTime? get lastUpdated {
    final age = HiveService.cacheAge(HiveService.cacheLeaderboard);
    if (age == null) return null;
    return DateTime.now().subtract(age);
  }
}
