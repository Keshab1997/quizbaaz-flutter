import 'package:flutter/material.dart';

/// Renders a player's name with an optional animated gradient "name effect".
///
/// Pass the effect id (`fire_name`, `rainbow_name`, `gold_name`) from the
/// shop; when it is null/empty the text renders exactly like a normal [Text].
class NameEffectText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final String? effectId;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int maxLines;

  const NameEffectText(
    this.text, {
    required this.style,
    this.effectId,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines = 1,
    super.key,
  });

  @override
  State<NameEffectText> createState() => _NameEffectTextState();
}

class _NameEffectTextState extends State<NameEffectText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The gradient palette for each effect. First and last color match so the
  /// sliding animation loops seamlessly.
  List<Color> _colorsFor(String effectId) {
    switch (effectId) {
      case 'fire_name':
        return const [
          Color(0xFFFF3B30),
          Color(0xFFFF9500),
          Color(0xFFFFCC00),
          Color(0xFFFF9500),
          Color(0xFFFF3B30),
        ];
      case 'rainbow_name':
        return const [
          Color(0xFFFF2D55),
          Color(0xFFFF9500),
          Color(0xFFFFCC00),
          Color(0xFF34C759),
          Color(0xFF007AFF),
          Color(0xFFAF52DE),
          Color(0xFFFF2D55),
        ];
      case 'gold_name':
        return const [
          Color(0xFFBF953F),
          Color(0xFFFCF6BA),
          Color(0xFFB38728),
          Color(0xFFFBF5B7),
          Color(0xFFBF953F),
        ];
      default:
        return const [Colors.white, Colors.white];
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectId = widget.effectId;
    if (effectId == null || effectId.isEmpty) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      );
    }

    final colors = _colorsFor(effectId);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlideGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      ),
    );
  }
}

/// Slides the gradient horizontally across the text so the colors shimmer.
class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}
