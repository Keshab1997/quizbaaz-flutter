import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../models/question_model.dart';
import '../models/chapter_model.dart';
import '../models/champion_model.dart';
import '../models/leaderboard_model.dart';

class QuizRepository {
  // Load Daily Quiz Questions
  Future<List<QuestionModel>> getDailyQuizQuestions() async {
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonDailyQuiz);
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List list = data['questions'] ?? [];
      return list.map((q) => QuestionModel.fromJson(q)).toList();
    } catch (e) {
      // Return default questions if asset load fails
      return [
        QuestionModel(
          id: 'dq_01',
          question: 'What is the powerhouse of the cell?',
          questionBn: 'কোষের শক্তিঘর কাকে বলা হয়?',
          options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi Body'],
          correctIndex: 1,
          explanation: 'Mitochondria generate energy for cellular activities.',
        ),
        QuestionModel(
          id: 'dq_02',
          question: 'Which language is used for Flutter?',
          questionBn: 'ফ্লাটার কোন ভাষায় লেখা হয়?',
          options: ['Kotlin', 'Swift', 'Dart', 'Java'],
          correctIndex: 2,
          explanation: 'Dart is the official programming language for Flutter.',
        ),
      ];
    }
  }

  // Load Chapter List
  Future<List<CategoryModel>> getCategoriesAndChapters() async {
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonChapters);
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List list = data['categories'] ?? [];
      return list.map((c) => CategoryModel.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  // Load Questions for a specific chapter
  Future<List<QuestionModel>> getChapterQuestions(String jsonFilePath) async {
    try {
      final jsonStr = await rootBundle.loadString(jsonFilePath);
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List list = data['questions'] ?? [];
      return list.map((q) => QuestionModel.fromJson(q)).toList();
    } catch (e) {
      return [];
    }
  }

  // Load Yesterday's Champions
  Future<List<ChampionModel>> getYesterdayChampions() async {
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonChampions);
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List list = data['champions'] ?? [];
      return list.map((c) => ChampionModel.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  // Load Live Leaderboard
  Future<List<LeaderboardItem>> getLiveLeaderboard() async {
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonLeaderboard);
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List list = data['top_ranks'] ?? [];
      return list.map((item) => LeaderboardItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }
}
