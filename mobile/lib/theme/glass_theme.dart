import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tokens for the light glass look (onboarding and main screens): one navy accent on soft grey.
class GlassTheme {
  GlassTheme._();

  static const Color navy = AppColors.primary;
  static const Color navySoft = AppColors.accent;
  static const Color ink = AppColors.dark;
  static const Color textMuted = AppColors.secondaryLabel;

  /// Navy gradient used for buttons and highlighted icons
  static const List<Color> accentGradient = [AppColors.primary, AppColors.accent];
}

/// Calm animated background: soft grey-white gradient with two faint navy glows drifting slowly.
/// Put content in [child]; the backdrop fills the whole screen behind it.
class AuroraBackdrop extends StatefulWidget {
  final Widget child;

  const AuroraBackdrop({super.key, required this.child});

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFAFBFC), AppColors.background],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, _) => CustomPaint(painter: _GlowPainter(_loop.value)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double t;
  _GlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    glow.color = AppColors.primary.withValues(alpha: 0.07);
    canvas.drawCircle(
      Offset(size.width * (0.1 + 0.08 * math.sin(a)), size.height * (0.12 + 0.04 * math.cos(a))),
      size.width * 0.55,
      glow,
    );

    glow.color = AppColors.accent.withValues(alpha: 0.06);
    canvas.drawCircle(
      Offset(size.width * (0.95 + 0.06 * math.cos(a)), size.height * (0.78 + 0.04 * math.sin(a))),
      size.width * 0.6,
      glow,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}

/// Frosted white panel: blurs what is behind it, with a soft border and shadow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.blur = 16,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.07), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: Colors.white.withValues(alpha: 0.78),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Paints [child] (usually an Icon or Text) with a gradient.
class NeonGradient extends StatelessWidget {
  final Widget child;
  final List<Color> colors;

  const NeonGradient({super.key, required this.child, this.colors = GlassTheme.accentGradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect),
      child: child,
    );
  }
}

/// Full-width navy gradient button with a soft shadow.
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final List<Color> colors;
  final VoidCallback? onPressed;

  const NeonButton({
    super.key,
    required this.label,
    this.colors = GlassTheme.accentGradient,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: enabled ? 1 : 0.35,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: colors),
          boxShadow: enabled
              ? [BoxShadow(color: colors.first.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
