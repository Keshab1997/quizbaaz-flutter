import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/providers/locale_provider.dart';
import '../../data/services/translation_service.dart';
import '../../l10n/app_strings.dart';

/// Renders [text] in the user's chosen quiz language.
///
/// When `LocaleProvider.quizLanguage` is `null` (the default) this is exactly a
/// [Text] widget with zero overhead — no network, no rebuild cost. Once the
/// user picks a language it fetches a translation through
/// [TranslationService], which caches results on disk, so the same question
/// only ever costs one request in the app's lifetime.
///
/// While a first-time translation is in flight the *original* text stays
/// visible (dimmed) rather than a spinner, so the quiz timer is never spent
/// staring at a blank card.
class TranslatableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final target = context.watch<LocaleProvider>().quizLanguage;

    if (target == null || text.trim().isEmpty) {
      return _plain(text, dimmed: false);
    }

    // Already on disk → render synchronously, no flicker between questions.
    if (TranslationService.isCached(text, target)) {
      return FutureBuilder<String>(
        future: TranslationService.translate(text, targetLanguage: target),
        initialData: text,
        builder: (_, snapshot) => _plain(snapshot.data ?? text, dimmed: false),
      );
    }

    return FutureBuilder<String>(
      // Keyed by text+language so switching either one restarts cleanly.
      key: ValueKey('$target::$text'),
      future: TranslationService.translate(text, targetLanguage: target),
      builder: (_, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        return _plain(snapshot.data ?? text, dimmed: waiting);
      },
    );
  }

  Widget _plain(String value, {required bool dimmed}) {
    final resolved = style ?? const TextStyle();
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.45 : 1.0,
      child: Text(
        value,
        style: resolved,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Single translate control for a whole quiz, designed to sit in the AppBar.
///
/// Deliberately *not* per question: a chip on every card is visual noise and
/// makes the player think they have to act again on each screen. One tap here
/// sets the language for the entire session — every question, option and
/// explanation that follows is already translated.
///
/// [texts] supplies everything the quiz will eventually show. As soon as a
/// language is chosen the whole list is translated in the background and
/// written to the cache, so question 2 onwards appears instantly instead of
/// fetching mid-countdown.
class QuizTranslateButton extends StatefulWidget {
  /// Every string the quiz can display, gathered up front.
  final List<String> Function() texts;

  const QuizTranslateButton({super.key, required this.texts});

  @override
  State<QuizTranslateButton> createState() => _QuizTranslateButtonState();
}

class _QuizTranslateButtonState extends State<QuizTranslateButton> {
  bool _prefetching = false;

  Future<void> _open() async {
    final before = context.read<LocaleProvider>().quizLanguage;
    await showLanguagePickerSheet(context);
    if (!mounted) return;

    final after = context.read<LocaleProvider>().quizLanguage;
    if (after == null || after == before) return;

    await _prefetch(after);
  }

  /// Warms the cache, front-loading what the player sees next.
  ///
  /// Only the first [_eagerCount] strings are awaited — roughly the current
  /// and next question. The rest are queued and trickle in while the player
  /// reads, because the free translation endpoints answer 429 to a burst and
  /// a 10-question quiz is around 60 strings.
  static const int _eagerCount = 12;

  Future<void> _prefetch(String language) async {
    final unique = widget.texts().toSet().toList();
    if (unique.isEmpty) return;

    setState(() => _prefetching = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(S.translating),
      ));

    final eager = unique.take(_eagerCount).toList();
    final rest = unique.skip(_eagerCount).toList();

    List<String> translated = const [];
    try {
      translated =
          await TranslationService.translateAll(eager, targetLanguage: language);
    } catch (_) {
      // Ignored: each TranslatableText retries and falls back on its own.
    }

    // Everything else fills in quietly behind the player.
    if (rest.isNotEmpty) {
      TranslationService.warm(rest, targetLanguage: language);
    }

    if (!mounted) return;
    setState(() => _prefetching = false);

    // If not a single string came back changed, the providers are refusing —
    // say so once instead of leaving the player wondering.
    final everythingUnchanged = translated.isNotEmpty &&
        List.generate(eager.length, (i) => translated[i] == eager[i])
            .every((same) => same);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(
          everythingUnchanged
              ? S.translateFailed
              : '${S.translateButton}: '
                  '${TranslationService.languageName(language)}',
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final target = context.watch<LocaleProvider>().quizLanguage;

    if (target == null || text.trim().isEmpty) {
      return _plain(text, dimmed: false);
    }

    // Already on disk → render synchronously, no flicker between questions.
    if (TranslationService.isCached(text, target)) {
      return FutureBuilder<String>(
        future: TranslationService.translate(text, targetLanguage: target),
        initialData: text,
        builder: (_, snapshot) => _plain(snapshot.data ?? text, dimmed: false),
      );
    }

    return FutureBuilder<String>(
      // Keyed by text+language so switching either one restarts cleanly.
      key: ValueKey('$target::$text'),
      future: TranslationService.translate(text, targetLanguage: target),
      builder: (_, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        return _plain(snapshot.data ?? text, dimmed: waiting);
      },
    );
  }

  Widget _plain(String value, {required bool dimmed}) {
    final resolved = style ?? const TextStyle();
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.45 : 1.0,
      child: Text(
        value,
        style: resolved,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Single translate control for a whole quiz, designed to sit in the AppBar.
///
/// Deliberately *not* per question: a chip on every card is visual noise and
/// makes the player think they have to act again on each screen. One tap here
/// sets the language for the entire session — every question, option and
/// explanation that follows is already translated.
///
/// [texts] supplies everything the quiz will eventually show. As soon as a
/// language is chosen the whole list is translated in the background and
/// written to the cache, so question 2 onwards appears instantly instead of
/// fetching mid-countdown.
class QuizTranslateButton extends StatefulWidget {
  /// Every string the quiz can display, gathered up front.
  final List<String> Function() texts;

  const QuizTranslateButton({super.key, required this.texts});

  @override
  State<QuizTranslateButton> createState() => _QuizTranslateButtonState();
}

class _QuizTranslateButtonState extends State<QuizTranslateButton> {
  bool _prefetching = false;

  Future<void> _open() async {
    final before = context.read<LocaleProvider>().quizLanguage;
    await showLanguagePickerSheet(context);
    if (!mounted) return;

    final after = context.read<LocaleProvider>().quizLanguage;
    if (after == null || after == before) return;

    await _prefetch(after);
  }

  /// Warms the cache for the rest of the quiz. Failures are ignored on
  /// purpose — every individual [TranslatableText] retries and falls back to
  /// the original text, so a half-finished prefetch is never fatal.
  Future<void> _prefetch(String language) async {
    setState(() => _prefetching = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(S.translating),
      ));

    try {
      final unique = widget.texts().toSet().toList();
      await TranslationService.translateAll(unique, targetLanguage: language);
    } catch (_) {
      // Ignored: per-widget translation still handles this text later.
    }

    if (!mounted) return;
    setState(() => _prefetching = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          '${S.translateButton}: ${TranslationService.languageName(language)}',
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final target = context.watch<LocaleProvider>().quizLanguage;
    final isActive = target != null;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: isActive
            ? TranslationService.languageName(target)
            : S.translateTo,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _prefetching ? null : _open,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive
                  ? AppColors.neonCyan.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: isActive
                    ? AppColors.neonCyan.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_prefetching)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neonCyan,
                    ),
                  )
                else
                  Icon(
                    Icons.translate_rounded,
                    size: 16,
                    color: isActive
                        ? AppColors.neonCyan
                        : AppColors.textSecondary,
                  ),
                if (isActive) ...[
                  const SizedBox(width: 5),
                  Text(
                    target.split('-').first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: AppColors.neonCyan,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing every language [TranslationService] can translate into,
/// with a search field because the list is long by design.
Future<void> showLanguagePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ChangeNotifierProvider<LocaleProvider>.value(
      value: context.read<LocaleProvider>(),
      child: const _LanguagePickerSheet(),
    ),
  );
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet();

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final selected = localeProvider.quizLanguage;

    final entries = TranslationService.supportedLanguages.entries
        .where((e) =>
            _query.isEmpty ||
            e.value.toLowerCase().contains(_query.toLowerCase()) ||
            e.key.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Icon(Icons.translate_rounded,
                      color: AppColors.neonCyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.translateTo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                S.translateDefaultHint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                autofocus: false,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: S.translateSearchLanguage,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _LanguageTile(
                    label: S.translateShowOriginal,
                    icon: Icons.format_clear_rounded,
                    selected: selected == null,
                    onTap: () {
                      localeProvider.setQuizLanguage(null);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  for (final entry in entries)
                    _LanguageTile(
                      label: entry.value,
                      selected: selected == entry.key,
                      onTap: () {
                        localeProvider.setQuizLanguage(entry.key);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: icon == null
          ? null
          : Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? AppColors.neonCyan : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.neonCyan, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
