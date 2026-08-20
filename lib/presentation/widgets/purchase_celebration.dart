import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Fast, lightweight purchase celebration overlay.
///
/// Replaces the slow, queued SnackBar with an instant auto-dismissing dialog:
/// a bouncing 3D mascot + confetti burst + item details.
///
/// No `BackdropFilter` is used anywhere in this widget, so it renders
/// instantly even on mid-range devices (blur is the main cause of jank).
class PurchaseCelebration {
  static bool _showing = false;

  static void show(
    BuildContext context, {
    required String itemName,
    required String subtitle,
    required String characterAsset,
    required IconData itemIcon,
    required Color accent,
  }) {
    // Never stack celebrations on rapid taps — just show the latest one fast.
    if (_showing) return;
    _showing = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'purchase-celebration',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _CelebrationOverlay(
          itemName: itemName,
          subtitle: subtitle,
          characterAsset: characterAsset,
          itemIcon: itemIcon,
          accent: accent,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    ).whenComplete(() => _showing = false);
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final String itemName;
  final String subtitle;
  final String characterAsset;
  final IconData itemIcon;
  final Color accent;

  const _CelebrationOverlay({
    required this.itemName,
    required this.subtitle,
    required this.characterAsset,
    required this.itemIcon,
    required this.accent,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late final Animation<double> _scale;
  late final Animation<Offset> _textSlide;
  late final ConfettiController _confetti;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();

    _scale = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pop, curve: Curves.easeOutCubic));

    _confetti = ConfettiController(duration: const Duration(milliseconds: 800));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());

    // Auto-dismiss quickly so the flow never feels stuck.
    _dismissTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _confetti.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color onAccent =
        widget.accent == AppColors.neonGold ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: -math.pi / 2,
              emissionFrequency: 0.03,
              numberOfParticles: 16,
              maxBlastForce: 18,
              minBlastForce: 7,
              gravity: 0.28,
              shouldLoop: false,
              colors: const [
                AppColors.neonGold,
                AppColors.neonPurple,
                AppColors.neonCyan,
                AppColors.neonPink,
                AppColors.neonGreen,
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D mascot with a springy pop-in.
              ScaleTransition(
                scale: _scale,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.asset(
                      widget.characterAsset,
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.celebration,
                        size: 120,
                        color: widget.accent,
                      ),
                    ),
                    // Item icon badge.
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accent,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(widget.itemIcon, size: 24, color: onAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _pop,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    children: [
                      const Text(
                        '🎉 Purchased!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.itemName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap anywhere to continue',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
