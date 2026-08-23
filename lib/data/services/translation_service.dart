import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'hive_service.dart';

/// On-demand machine translation for **quiz content** (questions, options,
/// explanations).
///
/// Why translate at runtime instead of shipping translated question banks:
/// the bank grows every week and is authored once, in English. Maintaining 36
/// language variants by hand is not realistic, but a learner in Chennai still
/// wants the question in Tamil.
///
/// ## Rate limiting is the whole design
///
/// The free Google endpoint answers **HTTP 429** the moment you burst at it —
/// a 10-question quiz is ~60 strings, and firing those in parallel gets every
/// one of them rejected. So requests are not sent directly; they go through a
/// single-worker queue that:
///
/// * sends **one request at a time**, spaced by [_minInterval];
/// * retries a failed string with exponential backoff and jitter;
/// * puts a provider into **cooldown** after repeated 429s and transparently
///   falls through to the next provider;
/// * caches every success in Hive for [cacheTtl], so a string is only ever
///   fetched once per device — the cache is what actually keeps request
///   volume near zero in normal use;
/// * logs a failure **once per cooldown**, not once per string.
///
/// ## Providers
///
/// 1. `google` — keyless `translate_a/single`. Fast and good, but unofficial
///    and aggressively rate limited.
/// 2. `mymemory` — documented free API, slower and lower quality, used only
///    when Google is cooling down.
/// 3. `cloud` — official Google Cloud Translation v2, used **only** if a key
///    is supplied at build time:
///
///    ```bash
///    flutter build apk --dart-define=TRANSLATE_API_KEY=xxxxx
///    ```
///
///    For a Play Store release this is the one that will not rate limit. The
///    keyless endpoint is fine for development and light use.
class TranslationService {
  TranslationService._();

  /// Translations are stable, so cache them for a long time.
  static const Duration cacheTtl = Duration(days: 90);

  /// Optional official API key, supplied with `--dart-define`.
  static const String _apiKey = String.fromEnvironment('TRANSLATE_API_KEY');

  /// Gap between outgoing requests. Slow enough that the free endpoint stays
  /// happy, fast enough that a 10-question quiz warms in a few seconds.
  static const Duration _minInterval = Duration(milliseconds: 220);

  /// How long a provider sits out after it starts refusing.
  static const Duration _cooldown = Duration(minutes: 2);

  static const int _maxAttempts = 3;

  // ------------------------------------------------------------- languages --

  /// Languages offered in the question-translate picker. Indian languages
  /// first — that is where the users are — then widely requested ones.
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

  // ----------------------------------------------------------------- state --

  static final List<_Job> _queue = [];
  static final Map<String, Future<String>> _inFlight = {};
  static final Map<String, DateTime> _coolingUntil = {};
  static bool _pumping = false;
  static DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  static int _rng = DateTime.now().microsecondsSinceEpoch & 0xFFFF;

  /// True while the queue still has work, so the UI can show progress.
  static bool get isBusy => _queue.isNotEmpty || _inFlight.isNotEmpty;

  /// Pending string count, for progress indicators.
  static int get pendingCount => _queue.length;

  // ------------------------------------------------------------------- API --

  /// Translates [text] into [targetLanguage].
  ///
  /// Returns [text] unchanged when it is empty, already in the target
  /// language, or when every provider fails — callers never need a try/catch
  /// and the UI degrades to the original wording.
  static Future<String> translate(
    String text, {
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || targetLanguage == sourceLanguage) {
      return Future.value(text);
    }

    final key = _cacheKey(trimmed, targetLanguage);

    final cached = HiveService.cacheGet(key, maxAge: cacheTtl);
    if (cached is String && cached.isNotEmpty) return Future.value(cached);

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final job = _Job(
      text: trimmed,
      original: text,
      target: targetLanguage,
      source: sourceLanguage,
      cacheKey: key,
    );

    _inFlight[key] = job.completer.future;
    _queue.add(job);
    unawaited(_pump());
    return job.completer.future;
  }

  /// Translates several strings, preserving order.
  static Future<List<String>> translateAll(
    List<String> texts, {
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) {
    return Future.wait(texts.map((t) => translate(
          t,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        )));
  }

  /// Queues [texts] without waiting for them.
  ///
  /// Used to warm the cache for the rest of a quiz while the player is still
  /// reading question one. Already-cached strings cost nothing, so this is
  /// safe to call repeatedly.
  static void warm(
    List<String> texts, {
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) {
    for (final text in texts) {
      unawaited(translate(
        text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      ).catchError((_) => text));
    }
  }

  /// True when this exact text is already on disk, so the UI can render it
  /// synchronously instead of flashing a placeholder.
  static bool isCached(String text, String targetLanguage) {
    final cached = HiveService.cacheGet(
      _cacheKey(text.trim(), targetLanguage),
      maxAge: cacheTtl,
    );
    return cached is String && cached.isNotEmpty;
  }

  /// Drops queued work — call when leaving a quiz so a half-finished warm-up
  /// does not keep hitting the network in the background.
  static void cancelPending() {
    for (final job in _queue) {
      _inFlight.remove(job.cacheKey);
      if (!job.completer.isCompleted) job.completer.complete(job.original);
    }
    _queue.clear();
  }

  @visibleForTesting
  static void resetForTest() {
    _queue.clear();
    _inFlight.clear();
    _coolingUntil.clear();
    _pumping = false;
  }

  // --------------------------------------------------------------- the pump --

  /// Single worker. Everything is serialised here; nothing else may call a
  /// provider directly.
  static Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;

    try {
      // Yield once so everything enqueued in this frame is visible before the
      // first request leaves. Without it a single translate() call would fire
      // synchronously and cancelPending() could never win the race.
      await Future<void>.delayed(Duration.zero);

      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);

        // Respect the minimum gap between outgoing requests.
        final since = DateTime.now().difference(_lastSentAt);
        if (since < _minInterval) {
          await Future<void>.delayed(_minInterval - since);
        }

        final result = await _resolve(job);
        _lastSentAt = DateTime.now();

        if (result != null && result.isNotEmpty) {
          await HiveService.cachePut(job.cacheKey, result);
        }
        _inFlight.remove(job.cacheKey);
        if (!job.completer.isCompleted) {
          job.completer.complete(result ?? job.original);
        }
      }
    } finally {
      _pumping = false;
    }
  }

  /// Tries each available provider, with backoff, until one answers.
  static Future<String?> _resolve(_Job job) async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      for (final provider in _availableProviders(job)) {
        try {
          final value = await _fetch(provider, job);
          if (value != null && value.isNotEmpty) {
            _coolingUntil.remove(provider);
            return value;
          }
        } on _RateLimited {
          _startCooldown(provider);
        } catch (e) {
          _logOnce(provider, '$e');
        }
      }

      // Every provider refused. Back off before the next round.
      if (attempt < _maxAttempts - 1) {
        final backoff = Duration(
          milliseconds: 400 * (1 << attempt) + _jitter(250),
        );
        await Future<void>.delayed(backoff);
      }
    }
    return null;
  }

  static List<String> _availableProviders(_Job job) {
    final now = DateTime.now();
    final providers = <String>[];

    if (_apiKey.isNotEmpty) providers.add('cloud');
    providers.add('google');
    // MyMemory caps a single query at 500 bytes.
    if (utf8.encode(job.text).length <= 500) providers.add('mymemory');

    final ready = providers
        .where((p) => !(_coolingUntil[p]?.isAfter(now) ?? false))
        .toList();

    // If everything is cooling down, try the first one anyway rather than
    // failing outright — the cooldown is a guess, not a contract.
    return ready.isEmpty ? providers.take(1).toList() : ready;
  }

  static void _startCooldown(String provider) {
    final until = DateTime.now().add(_cooldown);
    if (_coolingUntil[provider] == null ||
        _coolingUntil[provider]!.isBefore(DateTime.now())) {
      debugPrint(
        'TranslationService: $provider rate-limited (429). '
        'Pausing it for ${_cooldown.inMinutes} min and falling back.',
      );
    }
    _coolingUntil[provider] = until;
  }

  /// Prevents the console from filling with one identical line per string.
  static final Map<String, DateTime> _lastLoggedAt = {};

  static void _logOnce(String provider, String message) {
    final last = _lastLoggedAt[provider];
    final now = DateTime.now();
    if (last != null && now.difference(last) < const Duration(seconds: 30)) {
      return;
    }
    _lastLoggedAt[provider] = now;
    debugPrint('TranslationService[$provider]: $message');
  }

  static int _jitter(int maxMs) {
    // Cheap xorshift — good enough to de-synchronise retries, and avoids
    // pulling in dart:math just for this.
    _rng ^= _rng << 7;
    _rng ^= _rng >> 9;
    _rng &= 0xFFFF;
    return _rng % (maxMs + 1);
  }

  // ------------------------------------------------------------- providers --

  static Future<String?> _fetch(String provider, _Job job) {
    switch (provider) {
      case 'cloud':
        return _fetchCloud(job);
      case 'mymemory':
        return _fetchMyMemory(job);
      default:
        return _fetchGoogleFree(job);
    }
  }

  /// Keyless endpoint. Answers with a nested, position-based array:
  ///
  ///     [[["translated chunk","original chunk",null,null,1], ...], null,"en"]
  static Future<String?> _fetchGoogleFree(_Job job) async {
    final uri = Uri.parse('https://translate.googleapis.com/translate_a/single')
        .replace(queryParameters: {
      'client': 'gtx',
      'sl': job.source,
      'tl': job.target,
      'dt': 't',
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'q': job.text,
    });

    final response = await http
        .get(uri, headers: const {'User-Agent': 'Mozilla/5.0 (QuizBaaz)'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 429 || response.statusCode == 403) {
      throw const _RateLimited();
    }
    if (response.statusCode != 200) {
      throw TranslationFailure('google returned ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
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

  /// Documented free API. Needs a concrete source language — the quiz bank is
  /// authored in English, so `auto` resolves to `en`.
  static Future<String?> _fetchMyMemory(_Job job) async {
    final source = job.source == 'auto' ? 'en' : job.source;
    final uri = Uri.parse('https://api.mymemory.translated.net/get').replace(
      queryParameters: {'q': job.text, 'langpair': '$source|${job.target}'},
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 429) throw const _RateLimited();
    if (response.statusCode != 200) {
      throw TranslationFailure('mymemory returned ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) return null;
    if (body['quotaFinished'] == true) throw const _RateLimited();

    final data = body['responseData'];
    if (data is! Map) return null;
    final text = data['translatedText'];
    if (text is! String || text.isEmpty) return null;

    // The free tier reports quota problems as the translation itself.
    if (text.startsWith('MYMEMORY WARNING') ||
        text.contains('QUERY LENGTH LIMIT EXCEEDED')) {
      throw const _RateLimited();
    }
    return text.trim();
  }

  /// Official Cloud Translation v2 — only reachable when a key was supplied.
  static Future<String?> _fetchCloud(_Job job) async {
    final uri = Uri.parse('https://translation.googleapis.com/language/'
        'translate/v2?key=$_apiKey');

    final response = await http
        .post(uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': job.text,
              'target': job.target,
              if (job.source != 'auto') 'source': job.source,
              'format': 'text',
            }))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 429) throw const _RateLimited();
    if (response.statusCode != 200) {
      throw TranslationFailure('cloud returned ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final translations = body is Map ? body['data']?['translations'] : null;
    if (translations is! List || translations.isEmpty) return null;
    final text = translations.first['translatedText'];
    return text is String && text.isNotEmpty ? text.trim() : null;
  }

  // ----------------------------------------------------------------- cache --

  static String _cacheKey(String text, String target) {
    // Hash rather than store the raw text, so keys stay short and ASCII.
    final digest = text.hashCode.toUnsigned(32).toRadixString(36);
    return 'tr_${target}_${text.length}_$digest';
  }
}

/// A queued translation request.
class _Job {
  final String text;
  final String original;
  final String target;
  final String source;
  final String cacheKey;
  final Completer<String> completer = Completer<String>();

  _Job({
    required this.text,
    required this.original,
    required this.target,
    required this.source,
    required this.cacheKey,
  });
}

/// Provider is refusing traffic; try another one and cool this one down.
class _RateLimited implements Exception {
  const _RateLimited();

  @override
  String toString() => 'rate limited';
}

/// Any other non-success answer from a translation provider.
class TranslationFailure implements Exception {
  final String message;
  const TranslationFailure(this.message);

  @override
  String toString() => 'TranslationFailure: $message';
}
