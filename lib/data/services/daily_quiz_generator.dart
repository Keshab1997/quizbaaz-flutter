import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/question_model.dart';
import '../repositories/quiz_repository.dart';
import '../services/hive_service.dart';
import 'chapter_catalog_service.dart';
import 'question_bank_service.dart';

/// Generates a daily mixed question set by pooling questions across all
/// available chapter banks (bundled + Firestore) and seeding a randomizer
/// with today's date.
///
/// This guarantees that:
/// - Every player globally receives the EXACT same 10 mixed questions on any given day.
/// - Questions are freshly mixed every day at midnight (new date key).
/// - Questions come from diverse subjects (Maths, Science, History, etc.).
class DailyQuizGenerator {
  final QuestionBankService _bankService;
  final ChapterCatalogService _catalogService;
  final QuizRepository _quizRepository;

  DailyQuizGenerator({
    QuestionBankService? bankService,
    ChapterCatalogService? catalogService,
    QuizRepository? quizRepository,
  })  : _bankService = bankService ?? QuestionBankService(),
        _catalogService = catalogService ?? ChapterCatalogService(),
        _quizRepository = quizRepository ?? QuizRepository();

  /// Integer seed derived from date key `yyyyMMdd` (e.g. 20260825).
  static int _dateSeed(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// Date key string `yyyy-MM-dd`.
  static String dateKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Generates or fetches today's 10 mixed questions.
  Future<List<QuestionModel>> generateDailyQuestions({
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final targetDate = date ?? DateTime.now();
    final cacheKey = 'daily_quiz_mixed_${dateKey(targetDate)}';

    if (!forceRefresh) {
      final cached = HiveService.cacheGetList(cacheKey, maxAge: const Duration(hours: 24));
      if (cached.isNotEmpty) {
        return cached.map(QuestionModel.fromJson).toList();
      }
    }

    try {
      final pooledQuestions = <Map<String, dynamic>>[];
      final seenStems = <String>{};

      // 1. Fetch all bundled + remote category & chapter definitions
      final categories = await _quizRepository.getCategoriesAndChapters();

      for (final category in categories) {
        for (final chapter in category.chapters) {
          // Read asset questions for chapter
          if (chapter.jsonFile.isNotEmpty) {
            final assetRows = await _readJsonList(chapter.jsonFile, 'questions');
            for (final row in assetRows) {
              final q = QuestionModel.fromJson(row);
              final stem = q.questionText.resolve('en').trim().toLowerCase();
              if (stem.isNotEmpty && !seenStems.contains(stem)) {
                seenStems.add(stem);
                pooledQuestions.add(row);
              }
            }
          }

          // Read remote Firestore questions for chapter
          try {
            final remoteQuestions = await _bankService.fetchQuestions(chapter.chapterId);
            for (final q in remoteQuestions) {
              final stem = q.questionText.resolve('en').trim().toLowerCase();
              if (stem.isNotEmpty && !seenStems.contains(stem)) {
                seenStems.add(stem);
                pooledQuestions.add(q.toJson());
              }
            }
          } catch (e) {
            debugPrint('DailyQuizGenerator: remote fetch skipped for ${chapter.chapterId}');
          }
        }
      }

      if (pooledQuestions.isNotEmpty) {
        // Deterministic shuffle using today's date seed
        final rng = Random(_dateSeed(targetDate));
        final shuffled = [...pooledQuestions]..shuffle(rng);
        final countToTake = min(10, shuffled.length);
        final selected = shuffled.take(countToTake).toList();

        await HiveService.cachePut(cacheKey, selected);
        return selected.map(QuestionModel.fromJson).toList();
      }
    } catch (e) {
      debugPrint('DailyQuizGenerator: Error mixing daily questions — $e');
    }

    // Fallback: Read from bundled daily_quiz.json if available
    final fallbackRows = await _readJsonList('assets/data/daily_quiz.json', 'questions');
    if (fallbackRows.isNotEmpty) {
      await HiveService.cachePut(cacheKey, fallbackRows);
      return fallbackRows.map(QuestionModel.fromJson).toList();
    }

    return const [];
  }

  static Future<List<Map<String, dynamic>>> _readJsonList(String assetPath, String key) async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final list = data[key] as List<dynamic>? ?? const [];
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return const [];
    }
  }
}
