import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/battle_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../l10n/app_strings.dart';
import '../../widgets/cached_avatar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/quiz_language_pills.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          S.battleArena,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (battle.phase == BattlePhase.question ||
              battle.phase == BattlePhase.reveal)
            QuizLanguagePills(
              available: battle.availableLanguages,
              selected: battle.displayLanguage,
              onSelected: battle.setDisplayLanguage,
            ),
        ],
      ),
      body: switch (battle.phase) {
        BattlePhase.setup => const _SetupView(),
        BattlePhase.searching => const _SearchingView(),
        BattlePhase.found => const _VsIntroView(),
        BattlePhase.countdown => _CountdownView(
            countdownValue: battle.countdownValue,
          ),
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
    final battle = context.read<BattleProvider>();

    if (battle.hasNoQuestions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '😔 No questions available yet. Check back soon!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Image.asset(
          AppAssets.battleDuo,
          height: 130,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            AppAssets.battleSwords,
            height: 84,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '⚔️ BATTLE ARENA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          S.battleRulesLine(n: battle.battleQuestionCount),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          '⚡ ${battle.battleQuestionCount} questions • '
          'base ${battle.battleBasePoints} + speed ${battle.battleTimeBonusMax} '
          '+ streak ${battle.battleStreakBonus} pts',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.neonGold,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          S.battleChooseDifficulty,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        _difficultyCard(
          context,
          BattleDifficulty.easy,
          S.battleEasy,
          S.battleEasyDesc,
          AppColors.neonGreen,
        ),
        _difficultyCard(
          context,
          BattleDifficulty.normal,
          S.battleNormal,
          S.battleNormalDesc,
          AppColors.neonCyan,
        ),
        _difficultyCard(
          context,
          BattleDifficulty.hard,
          S.battleHard,
          S.battleHardDesc,
          AppColors.neonRed,
        ),
        const SizedBox(height: 20),
        NeonButton(
          text: S.battleStartFinding,
          onPressed: () => context.read<BattleProvider>().startBattle(_selected),
        ),
      ],
    );
  }

  Widget _difficultyCard(
    BuildContext context,
    BattleDifficulty diff,
    String title,
    String desc,
    Color accent,
  ) {
    final selected = _selected == diff;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selected = diff),
        child: GlassCard(
          borderRadius: 16,
          borderColor: selected ? accent : Colors.white12,
          backgroundColor: selected
              ? accent.withValues(alpha: 0.12)
              : AppColors.bgCardGlass,
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? accent : AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
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

// --------------------------------------------------------------- Searching ---

/// Matchmaking radar — shown while looking for a real opponent.
class _SearchingView extends StatefulWidget {
  const _SearchingView();

  @override
  State<_SearchingView> createState() => _SearchingViewState();
}

class _SearchingViewState extends State<_SearchingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radar;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _radar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _radar.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();
    final user = context.watch<UserProvider>().user;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radar rings
              AnimatedBuilder(
                animation: _radar,
                builder: (_, __) => CustomPaint(
                  size: const Size(230, 230),
                  painter: _RadarPainter(progress: _radar.value),
                ),
              ),
              // My avatar, breathing
              ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.06).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: _AvatarCircle(asset: user.effectiveAvatar, size: 64),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.battleSearching,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          S.battleSearchingHint,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          '${battle.difficulty.name.toUpperCase()} • '
          '${S.battleRulesLine(n: battle.battleQuestionCount)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.neonGold,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: battle.searchSecondsTotal == 0
                  ? 0
                  : 1 -
                      battle.searchSecondsRemaining /
                          battle.searchSecondsTotal,
              minHeight: 6,
              backgroundColor: Colors.white10,
              color: AppColors.neonCyan,
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.neonRed),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => context.read<BattleProvider>().cancelSearch(),
          child: Text(
            S.battleCancelSearch,
            style: const TextStyle(color: AppColors.neonRed),
          ),
        ),
      ],
    );
  }
}

/// Sweeping radar beam + fading rings.
class _RadarPainter extends CustomPainter {
  final double progress;

  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Static faint rings
    for (var i = 1; i <= 3; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.neonCyan.withValues(alpha: 0.18 - i * 0.04);
      canvas.drawCircle(center, maxR * i / 3, paint);
    }

    // Sweeping beam
    final beamPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        colors: [
          AppColors.neonCyan.withValues(alpha: 0.0),
          AppColors.neonCyan.withValues(alpha: 0.45),
          AppColors.neonCyan.withValues(alpha: 0.0),
        ],
        stops: const [0.82, 0.97, 1.0],
        transform: GradientRotation(progress * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, beamPaint);

    // Leading dot on the beam
    final dotAngle = progress * 2 * pi;
    final dotPos = center +
        Offset(cos(dotAngle), sin(dotAngle)) * (maxR * 0.82);
    canvas.drawCircle(
      dotPos,
      3.5,
      Paint()..color = AppColors.neonCyan,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------- VS intro ---

/// Cricket-league style VS splash: two cards slide in, "VS" slams in the
/// middle. Live matches get confetti + a LIVE badge.
class _VsIntroView extends StatefulWidget {
  const _VsIntroView();

  @override
  State<_VsIntroView> createState() => _VsIntroViewState();
}

class _VsIntroViewState extends State<_VsIntroView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final ConfettiController _confetti;
  bool _confettiFired = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _intro.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();
    final user = context.watch<UserProvider>().user;

    if (battle.isLive && !_confettiFired) {
      _confettiFired = true;
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) _confetti.play();
      });
    }

    final leftSlide = Tween<Offset>(
      begin: const Offset(-1.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    final rightSlide = Tween<Offset>(
      begin: const Offset(1.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.05, 0.5, curve: Curves.easeOutBack),
      ),
    );
    final vsScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.4, 0.72, curve: Curves.elasticOut),
      ),
    );
    final badgeFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti behind everything (live matches only)
        if (battle.isLive)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 14,
              gravity: 0.18,
              colors: const [
                AppColors.neonGold,
                AppColors.neonCyan,
                AppColors.neonPink,
                AppColors.neonGreen,
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SlideTransition(
                      position: leftSlide,
                      child: _VsPlayerCard(
                        name: S.you,
                        avatar: user.effectiveAvatar,
                        accent: AppColors.neonCyan,
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: vsScale,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.neonGold, Color(0xFFFF8E3C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonGold.withValues(alpha: 0.55),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1030),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SlideTransition(
                      position: rightSlide,
                      child: _VsPlayerCard(
                        name: battle.opponentName,
                        avatar: battle.opponentAvatar,
                        accent: AppColors.neonPink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              FadeTransition(
                opacity: badgeFade,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: battle.isLive
                          ? AppColors.neonGreen
                          : AppColors.neonPink,
                    ),
                    color: (battle.isLive
                            ? AppColors.neonGreen
                            : AppColors.neonPink)
                        .withValues(alpha: 0.12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (battle.isLive)
                        const SizedBox(
                          width: 9,
                          height: 9,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neonGreen,
                            ),
                          ),
                        ),
                      if (battle.isLive) const SizedBox(width: 8),
                      Text(
                        battle.isLive
                            ? S.battleLiveMatch
                            : S.battleBotMatch,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: battle.isLive
                              ? AppColors.neonGreen
                              : AppColors.neonPink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: badgeFade,
                child: Text(
                  S.battleFoundHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VsPlayerCard extends StatelessWidget {
  final String name;
  final String avatar;
  final Color accent;

  const _VsPlayerCard({
    required this.name,
    required this.avatar,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 22,
              ),
            ],
          ),
          child: ClipOval(
            child: _NetworkAwareAvatar(avatar: avatar),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Builds avatars for local assets or https URLs.
class _NetworkAwareAvatar extends StatelessWidget {
  final String avatar;

  const _NetworkAwareAvatar({required this.avatar});

  @override
  Widget build(BuildContext context) {
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return CachedAvatar(
        url: avatar,
        fit: BoxFit.cover,
        fallbackIcon: Icons.person_rounded,
        fallbackIconColor: Colors.white,
        fallbackIconSize: 34,
      );
    }
    return Image.asset(
      avatar,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String asset;
  final double size;

  const _AvatarCircle({required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: ClipOval(child: _NetworkAwareAvatar(avatar: asset)),
    );
  }
}

// --------------------------------------------------------------- Countdown ---

class _CountdownView extends StatelessWidget {
  final int countdownValue;

  const _CountdownView({required this.countdownValue});

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();
    final user = context.watch<UserProvider>().user;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VsPlayerCard(
                name: S.you,
                avatar: user.effectiveAvatar,
                accent: AppColors.neonCyan,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonGold,
                  ),
                ),
              ),
              _VsPlayerCard(
                name: battle.opponentName,
                avatar: battle.opponentAvatar,
                accent: AppColors.neonPink,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            battle.isLive
                ? '🔴 ${S.battleLiveMatch}'
                : '🤖 ${S.battleBotMatch}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              '$countdownValue',
              key: ValueKey(countdownValue),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: AppColors.neonGold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.battleGetReady,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _scoreboard(battle, user),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Q${battle.currentIndex + 1}/${battle.totalQuestions}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: battle.secondsRemaining <= 5
                    ? AppColors.neonRed.withValues(alpha: 0.15)
                    : AppColors.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: battle.secondsRemaining <= 5
                      ? AppColors.neonRed
                      : AppColors.neonCyan,
                ),
              ),
              child: Text(
                '⏱ ${battle.secondsRemaining}s',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: battle.secondsRemaining <= 5
                      ? AppColors.neonRed
                      : AppColors.neonCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _questionCard(context, question),
        const SizedBox(height: 16),

        ...question
            .optionsIn(battle.displayLanguage)
            .asMap()
            .entries
            .map((e) => _optionTile(battle, e.key, e.value)),

        const SizedBox(height: 12),
        _statusRow(battle),
      ],
    );
  }

  Widget _scoreboard(BattleProvider battle, UserModel user) {
    return Row(
      children: [
        Expanded(child: _playerCard(battle, user)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.neonGold,
            ),
          ),
        ),
        Expanded(child: _opponentCard(battle)),
      ],
    );
  }

  Widget _playerCard(BattleProvider battle, UserModel user) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AppColors.neonCyan.withValues(alpha: 0.5),
      child: Column(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: _AvatarCircle(asset: user.effectiveAvatar, size: 52),
          ),
          const SizedBox(height: 6),
          Text(
            S.you,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.neonCyan,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${battle.playerScore}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          _streakChip(battle.playerStreak, AppColors.neonCyan),
        ],
      ),
    );
  }

  Widget _opponentCard(BattleProvider battle) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AppColors.neonPink.withValues(alpha: 0.5),
      child: Column(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: _AvatarCircle(asset: battle.opponentAvatar, size: 52),
          ),
          const SizedBox(height: 6),
          Text(
            battle.opponentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.neonPink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${battle.opponentScore}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          _streakChip(battle.opponentStreak, AppColors.neonPink),
        ],
      ),
    );
  }

  Widget _streakChip(int streak, Color color) {
    if (streak < 2) return const SizedBox(height: 14);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        '🔥$streak',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Widget _questionCard(BuildContext context, QuestionModel question) {
    final language = context.watch<BattleProvider>().displayLanguage;
    final primary = question.questionIn(language);
    final secondary =
        language == 'en' ? null : question.questionIn('en');

    return GlassCard(
      borderRadius: 20,
      borderColor: AppColors.neonPurple.withValues(alpha: 0.3),
      backgroundColor: const Color(0x331E1B4B),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primary,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          if (secondary != null && secondary != primary) ...[
            const SizedBox(height: 8),
            Text(
              secondary,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
      } else if (index == battle.opponentSelected) {
        border = AppColors.neonPink;
        text = AppColors.neonPink;
        icon = Icons.cancel;
        tag = battle.opponentName;
      } else {
        text = AppColors.textMuted;
      }
    } else {
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
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        revealing && (index == correctIndex ||
                                index == battle.playerSelected ||
                                index == battle.opponentSelected)
                            ? FontWeight.bold
                            : FontWeight.w500,
                    color: text,
                  ),
                ),
              ),
              if (tag != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                  ),
                ),
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
          border: Border.all(
            color: AppColors.neonGold.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Text(
              battle.revealMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.neonGold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pointsSummary(
                  label: S.you,
                  pts: battle.lastRoundPlayer,
                  color: AppColors.neonCyan,
                ),
                Container(width: 1, height: 30, color: Colors.white12),
                _pointsSummary(
                  label: battle.opponentName,
                  pts: battle.lastRoundOpponent,
                  color: AppColors.neonPink,
                ),
              ],
            ),
          ],
        ),
      );
    }

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
          if (battle.playerAnswered && !battle.opponentAnswered) ...[
            if (battle.isLive)
              const Icon(Icons.check_circle, size: 16, color: AppColors.neonCyan)
            else
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.neonPink,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              battle.isLive
                  ? '${battle.opponentName} is answering…'
                  : '${battle.opponentName} is thinking…',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ] else if (battle.opponentAnswered && !battle.playerAnswered) ...[
            const Icon(Icons.check_circle, size: 16, color: AppColors.neonPink),
            const SizedBox(width: 8),
            Text(
              '${battle.opponentName} answered! Your turn…',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const Icon(Icons.bolt, size: 16, color: AppColors.neonGold),
            const SizedBox(width: 8),
            const Text(
              '🎯 Choose the right answer!',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pointsSummary({
    required String label,
    required BattleRoundPoints pts,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          '$label +${pts.total}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        if (pts.total > 0)
          Text(
            '${pts.base} + ${pts.timeBonus} + ${pts.streakBonus}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Result ---

class _ResultView extends StatelessWidget {
  const _ResultView();

  @override
  Widget build(BuildContext context) {
    final battle = context.watch<BattleProvider>();

    final String title;
    final String emoji;
    final Color color;
    if (battle.isForfeit) {
      title = '🏆 ${battle.opponentName} left — ${S.battleWinTitle}';
      emoji = '🏆';
      color = AppColors.neonGold;
    } else if (battle.isPlayerWin) {
      title = S.battleWinTitle;
      emoji = '🏆';
      color = AppColors.neonGold;
    } else if (battle.isDraw) {
      title = S.battleDrawTitle;
      emoji = '🤝';
      color = AppColors.neonCyan;
    } else {
      title = S.battleLoseTitle;
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
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'vs ${battle.opponentName} '
          '(${battle.difficulty.name} • '
          '${battle.isLive ? S.battleLiveMatch : S.battleBotMatch})',
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
              _resultStat(
                S.you,
                '${battle.playerScore}',
                '${battle.playerCorrect}/'
                '${battle.totalQuestions} ${S.correct}',
                AppColors.neonCyan,
              ),
              Container(width: 1, height: 60, color: Colors.white12),
              _resultStat(
                battle.opponentName,
                '${battle.opponentScore}',
                S.battleBotCorrect(n: battle.opponentCorrect),
                AppColors.neonPink,
              ),
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
                '+${battle.earnedCoins} ${S.coins}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonGold,
                ),
              ),
              if (battle.earnedGems > 0) ...[
                const SizedBox(width: 16),
                const Icon(Icons.diamond, color: AppColors.neonPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  '+${battle.earnedGems} ${S.gems}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonPurple,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        NeonButton(
          text: S.battleRematch,
          onPressed: () => context.read<BattleProvider>().rematch(),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: Text(
            S.battleBackHome,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultStat(String label, String score, String sub, Color color) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
