import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/battle_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/translatable_text.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/cached_avatar.dart';
import '../../../l10n/app_strings.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  /// Every string the battle can show, so one tap translates the whole match.
  List<String> _allBattleTexts(BattleProvider battle) {
    final texts = <String>[];
    for (final q in battle.questions) {
      texts.add(q.question);
      texts.addAll(q.options);
      if (q.explanation.isNotEmpty) texts.add(q.explanation);
    }
    return texts;
  }

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('1 vs 1 Battle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          QuizTranslateButton(texts: () => _allBattleTexts(battle)),
        ],
      ),
      body: switch (battle.phase) {
        BattlePhase.setup => const _SetupView(),
        BattlePhase.countdown => _CountdownView(countdownValue: battle.countdownValue, botName: battle.botName),
        BattlePhase.question || BattlePhase.reveal => const _ArenaView(),
        BattlePhase.finished => const _ResultView(),
      },
    );
  }
}

// ------------------------------------------------------------------ Setup ----

class _SetupView extends StatefulWidget {
  const _SetupView();

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  BattleDifficulty _selected = BattleDifficulty.normal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Image.asset(
          AppAssets.battleDuo,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            AppAssets.battleSwords,
            height: 90,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '⚔️ BATTLE ARENA',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
        ),
        const SizedBox(height: 4),
        Text(
          'Face a bot opponent in a '
          '${context.read<BattleProvider>().battleQuestionCount}-question '
          'head-to-head duel.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        const Text(
          'CHOOSE DIFFICULTY',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
        ),
        const SizedBox(height: 12),
        _difficultyCard(
          context,
          BattleDifficulty.easy,
          '😌 Easy',
          'Relaxed pace — the bot misses often',
          AppColors.neonGreen,
        ),
        _difficultyCard(
          context,
          BattleDifficulty.normal,
          '🙂 Normal',
          'Balanced — the bot keeps up with you',
          AppColors.neonCyan,
        ),
        _difficultyCard(
          context,
          BattleDifficulty.hard,
          '😈 Hard',
          'Ruthless — the bot rarely slips',
          AppColors.neonRed,
        ),
        const SizedBox(height: 24),
        NeonButton(
          text: '⚔️ FIND OPPONENT & START',
          onPressed: () => context.read<BattleProvider>().startBattle(_selected),
        ),
      ],
    );
  }

  Widget _difficultyCard(BuildContext context, BattleDifficulty diff, String title, String desc, Color accent) {
    final selected = _selected == diff;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selected = diff),
        child: GlassCard(
          borderRadius: 16,
          borderColor: selected ? accent : Colors.white12,
          backgroundColor: selected ? accent.withValues(alpha: 0.12) : AppColors.bgCardGlass,
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? accent : AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- Countdown ---

class _CountdownView extends StatelessWidget {
  final int countdownValue;
  final String botName;

  const _CountdownView({required this.countdownValue, required this.botName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _vsAvatar(AppAssets.maleAvatar, S.you),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('VS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.neonGold)),
              ),
              _vsAvatar(AppAssets.championBoy, 'BOT'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            botName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonCyan),
          ),
          const SizedBox(height: 30),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              '$countdownValue',
              key: ValueKey(countdownValue),
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: AppColors.neonGold),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Get ready...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _vsAvatar(String asset, String label) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: ClipOval(
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ------------------------------------------------------------------ Arena ---

class _ArenaView extends StatelessWidget {
  const _ArenaView();

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();
    final user = context.watch<UserProvider>().user;
    final question = battle.currentQuestion;

    if (question == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _scoreboard(battle, user),
        const SizedBox(height: 16),

        // Timer + question counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Q${battle.currentIndex + 1}/${battle.totalQuestions}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: battle.secondsRemaining <= 5 ? AppColors.neonRed.withValues(alpha: 0.15) : AppColors.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: battle.secondsRemaining <= 5 ? AppColors.neonRed : AppColors.neonCyan,
                ),
              ),
              child: Text(
                '⏱ ${battle.secondsRemaining}s',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: battle.secondsRemaining <= 5 ? AppColors.neonRed : AppColors.neonCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _questionCard(context, question),
        const SizedBox(height: 16),

        ...question.options.asMap().entries.map((e) => _optionTile(battle, e.key, e.value)),

        const SizedBox(height: 12),
        _statusRow(battle),
      ],
    );
  }

  bool _isNetworkAvatar(String avatar) =>
      avatar.startsWith('http://') || avatar.startsWith('https://');

  Widget _battleAvatar(UserModel user) {
    final avatar = user.effectiveAvatar.isNotEmpty ? user.effectiveAvatar : AppAssets.maleAvatar;
    final image = _isNetworkAvatar(avatar)
        ? CachedAvatar(
            url: avatar,
            fit: BoxFit.cover,
            fallbackIcon: Icons.person_rounded,
            fallbackIconColor: Colors.white,
            fallbackIconSize: 28,
          )
        : Image.asset(
            avatar,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          );

    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: image,
    );
  }

  Widget _scoreboard(BattleProvider battle, UserModel user) {
    return Row(
      children: [
        Expanded(child: _playerCard(battle, user)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('VS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neonGold)),
        ),
        Expanded(child: _botCard(battle)),
      ],
    );
  }

  Widget _playerCard(BattleProvider battle, UserModel user) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AppColors.neonCyan.withValues(alpha: 0.5),
      child: Column(
        children: [
          _battleAvatar(user),
          const SizedBox(height: 6),
          Text(S.you, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.neonCyan)),
          const SizedBox(height: 2),
          Text(
            '${battle.playerScore}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _botCard(BattleProvider battle) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AppColors.neonPink.withValues(alpha: 0.5),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage(AppAssets.championBoy),
          ),
          const SizedBox(height: 6),
          const Text('BOT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.neonPink)),
          const SizedBox(height: 2),
          Text(
            '${battle.botScore}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(BuildContext context, QuestionModel question) {
    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonPurple.withValues(alpha: 0.3),
      backgroundColor: const Color(0x331E1B4B),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatableText(
            question.question,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.35),
          ),
          if (question.questionBn != null &&
              context.watch<LocaleProvider>().quizLanguage == null) ...[
            const SizedBox(height: 8),
            Text(
              question.questionBn!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(BattleProvider battle, int index, String option) {
    final revealing = battle.phase == BattlePhase.reveal;
    final correctIndex = battle.currentQuestion?.correctIndex ?? 0;

    Color border = Colors.white.withValues(alpha: 0.15);
    Color text = AppColors.textPrimary;
    IconData icon = Icons.radio_button_unchecked;
    String? tag;

    if (revealing) {
      if (index == correctIndex) {
        border = AppColors.neonGreen;
        text = AppColors.neonGreen;
        icon = Icons.check_circle;
        tag = S.correct;
      } else if (index == battle.playerSelected) {
        border = AppColors.neonRed;
        text = AppColors.neonRed;
        icon = Icons.cancel;
        tag = S.you;
      } else if (index == battle.botSelected) {
        border = AppColors.neonPink;
        text = AppColors.neonPink;
        icon = Icons.cancel;
        tag = 'BOT';
      } else {
        text = AppColors.textMuted;
      }
    } else {
      // Question phase
      if (index == battle.playerSelected) {
        border = AppColors.neonCyan;
        text = AppColors.neonCyan;
        icon = Icons.check_circle;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: revealing ? null : () => battle.answerQuestion(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: border.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: text),
              const SizedBox(width: 10),
              Expanded(
                child: TranslatableText(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: revealing && (index == correctIndex || index == battle.playerSelected || index == battle.botSelected)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: text,
                  ),
                ),
              ),
              if (tag != null)
                Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: text)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(BattleProvider battle) {
    if (battle.phase == BattlePhase.reveal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.neonGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              battle.revealMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.neonGold),
            ),
            const SizedBox(height: 4),
            Text(
              'You +${battle.lastRoundPlayerPts}  •  Bot +${battle.lastRoundBotPts}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Question phase: show bot's thinking status
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (battle.botAnswered)
            const Icon(Icons.check_circle, size: 16, color: AppColors.neonPink)
          else
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonPink),
            ),
          const SizedBox(width: 8),
          Text(
            battle.botAnswered
                ? '${battle.botName} answered! Waiting for you...'
                : '${battle.botName} is thinking...',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Result --

class _ResultView extends StatelessWidget {
  const _ResultView();

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();

    final String title;
    final String emoji;
    final Color color;
    if (battle.isPlayerWin) {
      title = 'YOU WIN!';
      emoji = '🏆';
      color = AppColors.neonGold;
    } else if (battle.isDraw) {
      title = 'DRAW!';
      emoji = '🤝';
      color = AppColors.neonCyan;
    } else {
      title = 'BOT WINS!';
      emoji = '🤖';
      color = AppColors.neonPink;
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 20),
        Text(
          emoji,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 72),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          'vs ${battle.botName} (${battle.difficulty.name})',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        GlassCard(
          borderRadius: 20,
          borderColor: color.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _resultStat(S.you, '${battle.playerScore}', '${battle.playerCorrect} correct', AppColors.neonCyan),
              Container(width: 1, height: 60, color: Colors.white12),
              _resultStat('BOT', '${battle.botScore}', S.battleBotCorrect(n: battle.botCorrect), AppColors.neonPink),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassCard(
          borderRadius: 16,
          borderColor: AppColors.neonGold.withValues(alpha: 0.4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: AppColors.neonGold, size: 22),
              const SizedBox(width: 8),
              Text(
                '+${battle.earnedCoins} Coins',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonGold),
              ),
              if (battle.earnedGems > 0) ...[
                const SizedBox(width: 16),
                const Icon(Icons.diamond, color: AppColors.neonPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  '+${battle.earnedGems} Gems',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonPurple),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        NeonButton(
          text: '⚔️ REMATCH',
          onPressed: () => context.read<BattleProvider>().rematch(),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text(
            'Back to Home',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _resultStat(String label, String score, String sub, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(score, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
