import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/services/translation_service.dart';
import '../../../l10n/app_strings.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/translatable_text.dart';

/// Language settings.
///
/// Two separate controls on purpose:
///
/// * **App language** — hand-translated UI. Only the three catalogues we ship
///   appear here, because a machine-translated button label is a bad first
///   impression on a store listing.
/// * **Quiz language** — machine translation for question content, which can
///   be any of ~36 languages. A learner can read the interface in English and
///   the questions in Tamil, which is a very common real preference.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const _appLanguages = <String, String>{
    'en': 'English',
    'bn': 'বাংলা',
    'hi': 'हिन्दी',
  };

  static const _appLanguageSubtitles = <String, String>{
    'en': 'English',
    'bn': 'Bengali',
    'hi': 'Hindi',
  };

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          S.languageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            Text(
              S.languageSubtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // ------------------------------------------------ app language --
            _SectionLabel(S.languageAppSection),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _OptionTile(
                    title: S.languageSystemDefault,
                    subtitle: 'Auto',
                    icon: Icons.phone_android_rounded,
                    selected: localeProvider.followSystem,
                    onTap: () async {
                      await localeProvider.useSystemLanguage();
                      if (context.mounted) _toast(context);
                    },
                  ),
                  for (final entry in _appLanguages.entries)
                    _OptionTile(
                      title: entry.value,
                      subtitle: _appLanguageSubtitles[entry.key],
                      icon: Icons.language_rounded,
                      selected: !localeProvider.followSystem &&
                          localeProvider.appLanguage == entry.key,
                      onTap: () async {
                        await localeProvider.setAppLanguage(entry.key);
                        if (context.mounted) _toast(context);
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // ----------------------------------------------- quiz language --
            _SectionLabel(S.languageQuizSection),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.translateDefaultHint,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => showLanguagePickerSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.translate_rounded,
                              size: 19, color: AppColors.neonCyan),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localeProvider.quizLanguage == null
                                  ? S.translateShowOriginal
                                  : TranslationService.languageName(
                                      localeProvider.quizLanguage!),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.75)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${S.translatedBy} · ${S.translateOffline}',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(S.languageChanged)));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        size: 20,
        color: selected ? AppColors.neonCyan : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? AppColors.neonCyan : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.neonCyan, size: 20)
          : null,
    );
  }
}
