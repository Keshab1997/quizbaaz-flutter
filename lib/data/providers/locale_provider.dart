import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../services/hive_service.dart';
import '../services/translation_service.dart';

/// Owns the two independent language settings in the app:
///
/// * **App language** — the UI chrome (buttons, labels, dialogs). Limited to
///   the catalogues we actually ship: English, Bangla, Hindi.
/// * **Quiz language** — the language questions are auto-translated into by
///   [TranslationService]. This can be *any* language Google Translate knows,
///   because the text is translated at runtime rather than shipped with the
///   app. `null` means "leave questions in their original language".
///
/// Both values persist in the Hive meta box, so a returning user never has to
/// pick again.
class LocaleProvider extends ChangeNotifier {
  static const metaAppLanguage = 'app_language_code';
  static const metaQuizLanguage = 'quiz_language_code';
  static const metaFollowSystem = 'app_language_follow_system';

  String _appLanguage = 'en';
  String? _quizLanguage;
  bool _followSystem = true;

  /// Active UI language code — always one of [kSupportedLanguageCodes].
  String get appLanguage => _appLanguage;

  /// Target language for automatic question translation, or `null` when the
  /// user wants the original text.
  String? get quizLanguage => _quizLanguage;

  /// Whether the UI language tracks the device setting instead of an explicit
  /// choice.
  bool get followSystem => _followSystem;

  Locale get locale => Locale(_appLanguage);

  /// Reads persisted preferences and primes [S]. Safe to call more than once.
  ///
  /// Must run *after* `HiveService.initialize()`.
  void initialize() {
    _followSystem = HiveService.getMeta<bool>(metaFollowSystem) ?? true;
    final stored = HiveService.getMeta<String>(metaAppLanguage);
    _quizLanguage = HiveService.getMeta<String>(metaQuizLanguage);

    if (_followSystem || stored == null) {
      _appLanguage = _deviceLanguage();
    } else {
      _appLanguage = kSupportedLanguageCodes.contains(stored) ? stored : 'en';
    }

    S.load(_appLanguage);
    notifyListeners();
  }

  /// The device language if we ship a catalogue for it, otherwise English.
  String _deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return kSupportedLanguageCodes.contains(code) ? code : 'en';
  }

  /// Switches the UI language and remembers the choice.
  Future<void> setAppLanguage(String code) async {
    if (!kSupportedLanguageCodes.contains(code)) return;
    if (!_followSystem && _appLanguage == code) return;

    _appLanguage = code;
    _followSystem = false;
    S.load(code);
    await HiveService.setMeta(metaAppLanguage, code);
    await HiveService.setMeta(metaFollowSystem, false);
    notifyListeners();
  }

  /// Hands language selection back to the operating system.
  Future<void> useSystemLanguage() async {
    _followSystem = true;
    _appLanguage = _deviceLanguage();
    S.load(_appLanguage);
    await HiveService.setMeta(metaFollowSystem, true);
    await HiveService.setMeta(metaAppLanguage, null);
    notifyListeners();
  }

  /// Sets the auto-translate target for quiz questions. Pass `null` to turn
  /// automatic translation off.
  Future<void> setQuizLanguage(String? code) async {
    if (_quizLanguage == code) return;
    // Drop any warm-up still queued for the previous language, otherwise the
    // app keeps spending requests on text nobody will see.
    TranslationService.cancelPending();
    _quizLanguage = code;
    await HiveService.setMeta(metaQuizLanguage, code);
    notifyListeners();
  }

  /// Human-readable name for the current quiz language, for settings rows.
  String get quizLanguageLabel => _quizLanguage == null
      ? S.translateShowOriginal
      : TranslationService.languageName(_quizLanguage!);
}
