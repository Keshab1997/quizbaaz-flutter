import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/champion_model.dart';
import '../models/leaderboard_model.dart';
import '../repositories/quiz_repository.dart';

class UserProvider extends ChangeNotifier {
  final QuizRepository _repository = QuizRepository();

  UserModel _user = UserModel.defaultUser();
  List<ChampionModel> _champions = [];
  List<LeaderboardItem> _leaderboard = [];
  bool _isLoading = false;

  UserModel get user => _user;
  List<ChampionModel> get champions => _champions;
  List<LeaderboardItem> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;

  ChampionModel? get yesterdayTopChampion =>
      _champions.isNotEmpty ? _champions.first : null;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _champions = await _repository.getYesterdayChampions();
      _leaderboard = await _repository.getLiveLeaderboard();
    } catch (e) {
      debugPrint('Error loading user/champ data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void addRewards(int coinsWon, int gemsWon) {
    _user.coins += coinsWon;
    _user.gems += gemsWon;
    _user.playedTodayDailyQuiz = true;
    notifyListeners();
  }

  void setGuestMode(bool isGuest) {
    if (isGuest) {
      _user = UserModel.guestUser();
    } else {
      _user = UserModel.defaultUser();
    }
    notifyListeners();
  }

  void upgradeGuestToFullAccount(String name, String username) {
    _user = UserModel(
      userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      fullName: name,
      avatarPath: 'assets/images/characters/hero_boy_3d.png',
      coins: _user.coins + 500, // Welcome bonus
      gems: _user.gems + 20,
      dailyStreak: _user.dailyStreak,
      isGuest: false,
    );
    notifyListeners();
  }
}
