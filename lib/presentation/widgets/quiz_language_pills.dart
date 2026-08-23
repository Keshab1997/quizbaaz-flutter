import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Compact language switcher for the quiz screens.
///
/// Switching the **app** language mid-quiz is not an option: `MaterialApp` is
/// keyed on the language code so the whole tree rebuilds, which would drop the
/// player back on the dashboard and end the run. This changes only the
/// language the question is *displayed* in — the content already ships in all
/// three, so the switch is instant and offline.
///
/// It is also the more useful behaviour: a student reading in Bangla often
/// wants one glance at the English wording of a term, not a permanent change
/// to their whole interface.
///
/// ```text
///  [ EN ][ বাং ][ हिं ]
/// ```
///
/// Only languages the current question actually carries are offered, so a tab
/// can never do nothing.
class QuizLanguagePills extends StatelessWidget {
  /// Codes the current question has content for.
  final List<String> available;

  /// Currently displayed language.
  final String selected;

  final ValueChanged<String> onSelected;

  const QuizLanguagePills({
    super.key,
    required this.available,
    required this.selected,
    required this.onSelected,
  });

  /// Short labels, in each language's own script — an English abbreviation for
  /// Bangla would be the wrong signal on a language switcher.
  static const Map<String, String> _labels = {
    'en': 'EN',
    'bn': 'বাং',
    'hi': 'हिं',
  };

  @override
  Widget build(BuildContext context) {
    // One language means nothing to switch between; showing a lone dead tab
    // is worse than showing nothing.
    if (available.length < 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in available) _pill(code),
        ],
      ),
    );
  }

  Widget _pill(String code) {
    final isSelected = code == selected;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isSelected ? null : () => onSelected(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? AppColors.neonCyan : Colors.transparent,
        ),
        child: Text(
          _labels[code] ?? code.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            color: isSelected ? AppColors.bgDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
