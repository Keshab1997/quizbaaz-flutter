import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../widgets/glass_card.dart';
import '../quiz_result/quiz_result_screen.dart';

class DailyQuizScreen extends StatelessWidget {
  const DailyQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    if (quiz.isQuizCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuizResultScreen()),
        );
      });
    }

    final currentQ = quiz.currentQuestion;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Daily Live Quiz',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => _showExitDialog(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: AppColors.neonGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${quiz.score} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonGold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: currentQ == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Progress & Timer
                    _buildProgressAndTimer(quiz),
                    const SizedBox(height: 18),

                    // Lifelines Bar
                    _buildLifelines(context, quiz),
                    const SizedBox(height: 20),

                    // Question Card
                    _buildQuestionCard(currentQ),
                    const SizedBox(height: 24),

                    // 4 Options
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: currentQ.options.length,
                        itemBuilder: (context, index) {
                          return _buildOptionButton(context, quiz, currentQ, index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressAndTimer(QuizProvider quiz) {
    final timerPercent = quiz.secondsRemaining / 15.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${quiz.currentIndex + 1} of ${quiz.questions.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: quiz.secondsRemaining <= 5 ? AppColors.neonRed : AppColors.neonCyan,
                ),
                const SizedBox(width: 4),
                Text(
                  '${quiz.secondsRemaining}s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: quiz.secondsRemaining <= 5 ? AppColors.neonRed : AppColors.neonCyan,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: timerPercent,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              quiz.secondsRemaining <= 5 ? AppColors.neonRed : AppColors.neonCyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLifelines(BuildContext context, QuizProvider quiz) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLifelineBtn(
          label: '50-50',
          icon: Icons.filter_2,
          count: quiz.fiftyFiftyStock,
          onTap: () => _useFiftyFifty(context, quiz),
        ),
        _buildLifelineBtn(
          label: '+10s Freeze',
          icon: Icons.ac_unit,
          count: quiz.freezeTimeStock,
          onTap: () => _useFreezeTime(context, quiz),
        ),
        _buildLifelineBtn(
          label: 'Skip',
          icon: Icons.fast_forward,
          onTap: () => quiz.useSkipQuestion(),
        ),
      ],
    );
  }

  void _useFiftyFifty(BuildContext context, QuizProvider quiz) {
    if (quiz.useFiftyFifty()) return;

    final message = quiz.fiftyFiftyStock <= 0
        ? 'No 50-50 lifelines left! Buy more in the Shop. 🛒'
        : 'Already used 50-50 on this question.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _useFreezeTime(BuildContext context, QuizProvider quiz) {
    if (quiz.useFreezeTime()) return;

    final message = quiz.freezeTimeStock <= 0
        ? 'No +10s Freeze left! Buy more in the Shop. 🛒'
        : 'Freeze already used on this question.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildLifelineBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    int? count, // null = free / unlimited (e.g. Skip)
  }) {
    final bool outOfStock = count != null && count <= 0;
    final String displayLabel = count != null ? '$label ($count)' : label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: outOfStock ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: outOfStock ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: outOfStock ? AppColors.textSecondary : AppColors.neonCyan),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: outOfStock ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    return GlassCard(
      borderRadius: 22,
      borderColor: AppColors.neonPurple.withValues(alpha: 0.3),
      backgroundColor: const Color(0x331E1B4B),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          if (question.questionBn != null) ...[
            const SizedBox(height: 8),
            Text(
              question.questionBn!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    QuizProvider quiz,
    dynamic question,
    int index,
  ) {
    final isDisabled = quiz.disabledOptionIndices.contains(index);
    if (isDisabled) {
      return const SizedBox.shrink();
    }

    final isSelected = quiz.selectedOptionIndex == index;
    final isAnswerSubmitted = quiz.isAnswerSubmitted;
    final isCorrect = question.correctIndex == index;

    Color borderColor = Colors.white.withValues(alpha: 0.12);
    Color bgColor = Colors.white.withValues(alpha: 0.05);
    Color textColor = AppColors.textPrimary;
    Widget? trailingIcon;

    if (isAnswerSubmitted) {
      if (isCorrect) {
        borderColor = AppColors.neonGreen;
        bgColor = AppColors.neonGreen.withValues(alpha: 0.2);
        trailingIcon = const Icon(Icons.check_circle, color: AppColors.neonGreen);
      } else if (isSelected) {
        borderColor = AppColors.neonRed;
        bgColor = AppColors.neonRed.withValues(alpha: 0.2);
        trailingIcon = const Icon(Icons.cancel, color: AppColors.neonRed);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => quiz.selectOption(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isAnswerSubmitted && (isCorrect || isSelected)
                ? [
                    BoxShadow(
                      color: (isCorrect ? AppColors.neonGreen : AppColors.neonRed).withValues(alpha: 0.3),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.neonCyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  question.options[index],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingIcon != null) trailingIcon,
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Quit Live Quiz?'),
        content: const Text('If you leave now, your score for today will not be recorded on the leaderboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Quit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
