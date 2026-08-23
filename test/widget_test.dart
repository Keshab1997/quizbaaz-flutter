import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quizbaaz/data/models/user_stats.dart';
import 'package:quizbaaz/data/providers/locale_provider.dart';
import 'package:quizbaaz/data/services/hive_service.dart';
import 'package:quizbaaz/data/services/translation_service.dart';
import 'package:quizbaaz/l10n/app_strings.dart';
import 'package:quizbaaz/l10n/strings_bn.dart';
import 'package:quizbaaz/l10n/strings_en.dart';
import 'package:quizbaaz/l10n/strings_hi.dart';
import 'package:quizbaaz/main.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('quizbaaz_test_');
    Hive.init(tempDir.path);
    await HiveService.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('QuizBaazApp builds without crashing', (tester) async {
    await tester.pumpWidget(
      QuizBaazApp(localeProvider: LocaleProvider()..initialize()),
    );
    await tester.pump();

    expect(find.byType(QuizBaazApp), findsOneWidget);
  });

  group('localisation', () {
    tearDown(() => S.load('en'));

    test('every shipped catalogue covers all English keys', () {
      for (final entry in {'bn': kStringsBn, 'hi': kStringsHi}.entries) {
        final missing =
            kStringsEn.keys.where((k) => !entry.value.containsKey(k)).toList();
        expect(missing, isEmpty,
            reason: '${entry.key} is missing ${missing.length} key(s)');
      }
    });

    test('no translation invents a key the base language lacks', () {
      for (final entry in {'bn': kStringsBn, 'hi': kStringsHi}.entries) {
        final stray =
            entry.value.keys.where((k) => !kStringsEn.containsKey(k)).toList();
        expect(stray, isEmpty,
            reason: '${entry.key} has stray key(s): $stray');
      }
    });

    test('placeholders match across languages', () {
      final pattern = RegExp(r'\{(\w+)\}');
      Set<String> holders(String v) =>
          pattern.allMatches(v).map((m) => m.group(1)!).toSet();

      for (final entry in {'bn': kStringsBn, 'hi': kStringsHi}.entries) {
        for (final key in kStringsEn.keys) {
          final translated = entry.value[key];
          if (translated == null) continue;
          expect(holders(translated), holders(kStringsEn[key]!),
              reason: '${entry.key} placeholder mismatch on "$key"');
        }
      }
    });

    test('S switches catalogue and falls back to English', () {
      S.load('bn');
      expect(S.code, 'bn');
      expect(S.cancel, kStringsBn['cancel']);

      S.load('hi');
      expect(S.cancel, kStringsHi['cancel']);

      // An unsupported code must not throw — it degrades to English.
      S.load('xx');
      expect(S.code, 'en');
      expect(S.cancel, kStringsEn['cancel']);

      // A key nobody translated still resolves to something readable.
      expect(S.raw('definitely_not_a_key'), 'definitely_not_a_key');
    });

    test('fill substitutes every placeholder occurrence', () {
      expect(S.fill('{n} of {n} in {where}', {'n': 3, 'where': 'Howrah'}),
          '3 of 3 in Howrah');
      expect(S.chapterCount(n: 12), contains('12'));
    });

    test('language choice survives a restart', () async {
      final provider = LocaleProvider()..initialize();
      await provider.setAppLanguage('bn');
      expect(provider.appLanguage, 'bn');
      expect(provider.followSystem, isFalse);

      // A fresh provider reads the same Hive box a cold start would.
      final restarted = LocaleProvider()..initialize();
      expect(restarted.appLanguage, 'bn');
      expect(S.code, 'bn');

      await restarted.useSystemLanguage();
      expect(restarted.followSystem, isTrue);
    });

    test('translation short-circuits without touching the network', () async {
      // Empty text, whitespace and same-language requests must never queue a
      // request — these are the cases that used to burn the rate limit.
      expect(await TranslationService.translate('', targetLanguage: 'bn'), '');
      expect(
        await TranslationService.translate('   ', targetLanguage: 'bn'),
        '   ',
      );
      expect(
        await TranslationService.translate('Water',
            targetLanguage: 'en', sourceLanguage: 'en'),
        'Water',
      );
      expect(TranslationService.pendingCount, 0);
      expect(TranslationService.isBusy, isFalse);
    });

    test('cancelPending resolves queued work to the original text', () async {
      final pending = TranslationService.translate(
        'A string nobody has translated yet',
        targetLanguage: 'ta',
      );
      expect(TranslationService.pendingCount, greaterThan(0));

      TranslationService.cancelPending();
      expect(await pending, 'A string nobody has translated yet');
      expect(TranslationService.pendingCount, 0);
    });

    test('an untranslated string is not reported as cached', () {
      expect(
        TranslationService.isCached('Never seen before', 'ta'),
        isFalse,
      );
    });

    test('quiz translation language is independent of the UI language',
        () async {
      final provider = LocaleProvider()..initialize();
      await provider.setAppLanguage('en');
      await provider.setQuizLanguage('ta');

      expect(provider.appLanguage, 'en');
      expect(provider.quizLanguage, 'ta');

      await provider.setQuizLanguage(null);
      expect(provider.quizLanguage, isNull);
    });
  });

  test('a fresh install starts with zeroed stats (no fake data)', () {
    final stats = HiveService.loadStats();
    expect(stats.totalAnswered, 0);
    expect(stats.totalCorrect, 0);
    expect(stats.hasData, isFalse);
    expect(stats.accuracyLabel, '--');
  });

  test('stats survive a Hive round-trip', () async {
    final stats = UserStats.empty()
      ..recordQuiz(
        answered: 10,
        correct: 8,
        timeSeconds: 60,
        isDaily: true,
        dailyScore: 120,
      );
    await HiveService.saveStats(stats);

    final restored = HiveService.loadStats();
    expect(restored.totalAnswered, 10);
    expect(restored.totalCorrect, 8);
    expect(restored.accuracyRounded, 80);
    expect(restored.bestDailyScore, 120);
  });

  test('offline writes are queued and can be drained', () async {
    await HiveService.clearPending();
    await HiveService.enqueuePending('save_user', {'user_id': 'u1'});
    expect(HiveService.pendingCount, 1);

    final ops = HiveService.pendingOps();
    expect(ops.first.value['type'], 'save_user');

    await HiveService.removePending(ops.first.key);
    expect(HiveService.pendingCount, 0);
  });
}
