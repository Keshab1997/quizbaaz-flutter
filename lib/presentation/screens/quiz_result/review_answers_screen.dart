import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/answer_record.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../widgets/glass_card.dart';

/// Shows every question of the finished quiz with the player's answer,
/// the correct answer and the explanation.
class ReviewAnswersScreen extends StatelessWidget {
  const ReviewAnswersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final records = quiz.answerRecords;

    final skippedCount =
        records.where((r) => r.status == AnswerStatus.skipped).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Review Answers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'No answers to review yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _buildSummary(quiz, skippedCount),
                const SizedBox(height: 16),
                ...records.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuestionReviewCard(
                          index: entry.key,
                          record: entry.value,
                        ),
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _buildSummary(QuizProvider quiz, int skippedCount) {
    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonGold.withValues(alpha: 0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryStat('Score', '${quiz.score}', AppColors.neonGold),
          _summaryStat('Correct', '${quiz.correctCount}', AppColors.neonGreen),
          _summaryStat('Wrong', '${quiz.wrongCount}', AppColors.neonRed),
          _summaryStat('Skipped', '$skippedCount', AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final int index;
  final AnswerRecord record;

  const _QuestionReviewCard({required this.index, required this.record});

  @override
  Widget build(BuildContext context) {
    final q = record.question;

    return GlassCard(
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusBadge(),
              const Spacer(),
              Text(
                'Q${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          if (q.questionBn != null && q.questionBn!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              q.questionBn!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          ...q.options.asMap().entries.map((entry) {
            final i = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOption(i, q.options[i]),
            );
          }),
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Explanation',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge() {
    final (String text, Color color, IconData icon) = switch (record.status) {
      AnswerStatus.answered => record.wasCorrect
          ? ('Correct', AppColors.neonGreen, Icons.check_circle)
          : ('Wrong', AppColors.neonRed, Icons.cancel),
      AnswerStatus.timedOut => ('Time\'s up', AppColors.neonGold, Icons.timer),
      AnswerStatus.skipped => ('Skipped', AppColors.textMuted, Icons.fast_forward),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String option) {
    final q = record.question;
    final isCorrectOption = index == q.correctIndex;
    final isUserPick = record.status == AnswerStatus.answered &&
        record.selectedIndex == index;
    final wasCorrect = record.wasCorrect;

    Color borderColor = Colors.white.withValues(alpha: 0.1);
    Color textColor = AppColors.textSecondary;
    IconData icon = Icons.radio_button_unchecked;

    if (isCorrectOption) {
      borderColor = AppColors.neonGreen;
      textColor = AppColors.neonGreen;
      icon = Icons.check_circle;
    } else if (isUserPick && !wasCorrect) {
      borderColor = AppColors.neonRed;
      textColor = AppColors.neonRed;
      icon = Icons.cancel;
    }

    final String? tag = isCorrectOption
        ? 'Correct answer'
        : (isUserPick && !wasCorrect ? 'Your answer' : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCorrectOption || isUserPick
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: isCorrectOption || isUserPick
                    ? textColor
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (tag != null)
            Text(
              tag,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
            ),
        ],
      ),
    );
  }
}
