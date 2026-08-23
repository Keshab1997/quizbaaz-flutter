import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'hive_service.dart';

/// On-demand machine translation for **quiz content** (questions, options,
/// explanations).
///
/// Why runtime translation instead of shipping translated question banks:
/// the bank grows every week and is authored once, in English/Bangla. Asking
/// the author to maintain 40 language variants is not realistic, but a learner
/// in Chennai still wants the question in Tamil. So the UI chrome is
/// hand-translated (see `lib/l10n/`) and the *content* is translated on the fly
/// and cached forever locally.
///
/// Transport: Google's public `translate_a/single` endpoint (the same one the
/// translate widget uses). It needs no API key and no billing account, which
/// keeps the app free to run. It is rate-limited and unofficial, so:
///
/// * every result is cached in Hive for [cacheTtl] and reused offline;
/// * identical strings in flight are de-duplicated via [_inFlight];
/// * failures degrade to the original text instead of throwing.
///
/// If you later want a supported SLA, swap [_fetchTranslation] for the Cloud
/// Translation v2 REST call — nothing else in the app needs to change.
class TranslationService {
  TranslationService._();

  /// Translations are stable, so cache them for a long time.
  static const Duration cacheTtl = Duration(days: 90);

  static const String _endpoint = 'https://translate.googleapis.com/translate_a/single';

  /// De-duplicates concurrent requests for the same text+language.
  static final Map<String, Future<String>> _inFlight = {};

  /// Languages offered in the question-translate picker.
  ///
  /// Indian languages first (that is where the users are), then the widely
  /// requested international ones. Every code is a Google Translate code.
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'bn': 'বাংলা — Bengali',
    'hi': 'हिन्दी — Hindi',
    'ta': 'தமிழ் — Tamil',
    'te': 'తెలుగు — Telugu',
    'mr': 'मराठी — Marathi',
    'gu': 'ગુજરાતી — Gujarati',
    'kn': 'ಕನ್ನಡ — Kannada',
    'ml': 'മലയാളം — Malayalam',
    'pa': 'ਪੰਜਾਬੀ — Punjabi',
    'or': 'ଓଡ଼ିଆ — Odia',
    'as': 'অসমীয়া — Assamese',
    'ur': 'اردو — Urdu',
    'ne': 'नेपाली — Nepali',
    'si': 'සිංහල — Sinhala',
    'sa': 'संस्कृतम् — Sanskrit',
    'ar': 'العربية — Arabic',
    'fa': 'فارسی — Persian',
    'zh-CN': '中文 — Chinese',
    'ja': '日本語 — Japanese',
    'ko': '한국어 — Korean',
    'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu',
    'th': 'ไทย — Thai',
    'vi': 'Tiếng Việt',
    'fr': 'Français — French',
    'es': 'Español — Spanish',
    'pt': 'Português — Portuguese',
    'de': 'Deutsch — German',
    'it': 'Italiano — Italian',
    'ru': 'Русский — Russian',
    'tr': 'Türkçe — Turkish',
    'nl': 'Nederlands — Dutch',
    'pl': 'Polski — Polish',
    'uk': 'Українська — Ukrainian',
    'sw': 'Kiswahili',
  };

  /// Display name for [code], falling back to the raw code.
  static String languageName(String code) =>
      supportedLanguages[code] ?? code.toUpperCase();

  static String _cacheKey(String text, String target) {
    // Hash instead of the raw text so a very long question cannot blow past
    // Hive's key length comfort zone, and so keys stay ASCII.
    final digest = text.hashCode.toUnsigned(32).toRadixString(36);
    return 'tr_${target}_${text.length}_$digest';
  }

  /// Translates [text] into [targetLanguage].
  ///
  /// Returns the original [text] unchanged when it is empty, already in the
  /// target language, or when the network call fails — callers never need a
  /// try/catch.
  static Future<String> translate(
    String text, {
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    if (targetLanguage == sourceLanguage) return text;

    final key = _cacheKey(trimmed, targetLanguage);

    final cached = HiveService.cacheGet(key, maxAge: cacheTtl);
    if (cached is String && cached.isNotEmpty) return cached;

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _fetchTranslation(
      trimmed,
      target: targetLanguage,
      source: sourceLanguage,
    ).then((value) async {
      if (value != null && value.isNotEmpty) {
        await HiveService.cachePut(key, value);
        return value;
      }
      return text;
    }).catchError((Object e) {
      debugPrint('TranslationService: $e');
      return text;
    }).whenComplete(() => _inFlight.remove(key));

    _inFlight[key] = future;
    return future;
  }

  /// Translates several strings at once, preserving order.
  ///
  /// Used for a whole question (stem + options + explanation) so the card can
  /// flip to the new language in one frame instead of piecemeal.
  static Future<List<String>> translateAll(
    List<String> texts, {
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) {
    return Future.wait(
      texts.map(
        (t) => translate(
          t,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        ),
      ),
    );
  }

  /// True when a translation for this exact text is already on disk, so the UI
  /// can skip the spinner and render instantly.
  static bool isCached(String text, String targetLanguage) {
    final cached =
        HiveService.cacheGet(_cacheKey(text.trim(), targetLanguage), maxAge: cacheTtl);
    return cached is String && cached.isNotEmpty;
  }

  // ------------------------------------------------------------- transport --

  static Future<String?> _fetchTranslation(
    String text, {
    required String target,
    required String source,
  }) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'client': 'gtx',
      'sl': source,
      'tl': target,
      'dt': 't',
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'q': text,
    });

    final response = await http
        .get(uri, headers: const {'User-Agent': 'Mozilla/5.0 (QuizBaaz)'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw HttpException('translate returned ${response.statusCode}');
    }

    return _parse(utf8.decode(response.bodyBytes));
  }

  /// The endpoint answers with a nested, position-based array:
  ///
  ///     [[["translated chunk","original chunk",null,null,1], ...], null, "en"]
  ///
  /// Long text arrives split into several chunks, so every chunk is
  /// concatenated back together in order.
  static String? _parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty) return null;

    final segments = decoded.first;
    if (segments is! List) return null;

    final buffer = StringBuffer();
    for (final segment in segments) {
      if (segment is List && segment.isNotEmpty && segment.first is String) {
        buffer.write(segment.first as String);
      }
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }
}

/// Thrown internally when the endpoint answers with a non-200 status.
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}
