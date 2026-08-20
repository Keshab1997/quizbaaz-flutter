import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../models/chapter_model.dart';
import '../models/question_model.dart';
import '../services/hive_service.dart';

/// Question-bank access.
///
/// Questions are authored content (shipped as JSON assets and, later, pushed
/// from the admin panel), so they are cached in Hive after the first read and
/// served from there afterwards. Nothing here invents placeholder questions:
/// an unavailable bank returns an empty list and the UI shows an empty state.
class QuizRepository {
  static const _dailyCacheTtl = Duration(hours: 12);

  /// Daily quiz questions — Hive cache first, then the bundled bank.
  Future<List<QuestionModel>> getDailyQuizQuestions() async {
    final cached = HiveService.cacheGetList(
      HiveService.cacheDailyQuiz,
      maxAge: _dailyCacheTtl,
    );
    if (cached.isNotEmpty) {
      return cached.map(QuestionModel.fromJson).toList();
    }

    final rows = await _readJsonList(AppAssets.jsonDailyQuiz, 'questions');
    if (rows.isNotEmpty) {
      await HiveService.cachePut(HiveService.cacheDailyQuiz, rows);
    }
    return rows.map(QuestionModel.fromJson).toList();
  }

  /// Chapter/category tree — Hive cache first.
  Future<List<CategoryModel>> getCategoriesAndChapters() async {
    final cached = HiveService.cacheGetList(HiveService.cacheChapters);
    if (cached.isNotEmpty) {
      return cached.map(CategoryModel.fromJson).toList();
    }

    final rows = await _readJsonList(AppAssets.jsonChapters, 'categories');
    if (rows.isNotEmpty) {
      await HiveService.cachePut(HiveService.cacheChapters, rows);
    }
    return rows.map(CategoryModel.fromJson).toList();
  }

  /// Questions for one chapter, cached per file path.
  Future<List<QuestionModel>> getChapterQuestions(String jsonFilePath) async {
    final cacheKey = 'chapter_questions:$jsonFilePath';
    final cached = HiveService.cacheGetList(cacheKey);
    if (cached.isNotEmpty) {
      return cached.map(QuestionModel.fromJson).toList();
    }

    final rows = await _readJsonList(jsonFilePath, 'questions');
    if (rows.isNotEmpty) {
      await HiveService.cachePut(cacheKey, rows);
    }
    return rows.map(QuestionModel.fromJson).toList();
  }

  /// Drops every cached question bank (used after an admin upload).
  Future<void> invalidateQuestionCache() async {
    await HiveService.cacheRemove(HiveService.cacheDailyQuiz);
    await HiveService.cacheRemove(HiveService.cacheChapters);
  }

  // -------------------------------------------------------------- Helpers --

  Future<List<Map<String, dynamic>>> _readJsonList(
    String assetPath,
    String key,
  ) async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final list = data[key] as List<dynamic>? ?? const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      // No bank available — callers show an empty state.
      return const [];
    }
  }
}
