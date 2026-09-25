import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/glass_theme.dart';

class OnboardSlide {
  final IconData icon;

  /// Small icons that orbit the main illustration
  final List<IconData> satellites;

  final String title;
  final String subtitle;

  const OnboardSlide({
    required this.icon,
    required this.satellites,
    required this.title,
    required this.subtitle,
  });
}

/// One onboarding page: a floating frosted-glass tile with a navy icon and orbiting glass chips,
/// then the title and text. [pageOffset] is this page's distance from the centre (-1…1) while swiping.
class SlideView extends StatelessWidget {
  final OnboardSlide slide;
  final double pageOffset;
  final Animation<double> float;

  const SlideView({
    super.key,
    required this.slide,
    required this.pageOffset,
    required this.float,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final artSize = math.min(screenW * 0.74, 300.0);
    final visibility = (1 - pageOffset.abs()).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration: parallax, and turns slightly in 3D as it leaves the screen
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(pageOffset * screenW * 0.3, 0, 0)
              ..setEntry(3, 2, 0.0012)
              ..rotateY(pageOffset * 0.6),
            child: Opacity(
              opacity: visibility,
              child: AnimatedBuilder(
                animation: float,
                builder: (_, _) => _Illustration(slide: slide, size: artSize, t: float.value),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Transform.translate(
            offset: Offset(pageOffset * screenW * 0.15, 0),
            child: Opacity(
              opacity: visibility,
              child: Column(
                children: [
                  NeonGradient(
                    colors: const [GlassTheme.ink, GlassTheme.navy],
                    child: Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    slide.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: GlassTheme.textMuted, height: 1.55),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final OnboardSlide slide;
  final double size;

  /// 0…1, repeating: drives the gentle bob and the chips' orbit
  final double t;

  const _Illustration({required this.slide, required this.size, required this.t});

  @override
  Widget build(BuildContext context) {
    final angle = t * 2 * math.pi;
    final bob = math.sin(angle) * 9;
    final tile = size * 0.46;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Neon glow under the tile
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: GlassTheme.navy.withValues(alpha: 0.10), blurRadius: 70, spreadRadius: 6),
              ],
            ),
          ),
          // Orbit ring
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: GlassTheme.navy.withValues(alpha: 0.12), width: 1.2),
            ),
          ),
          for (var i = 0; i < slide.satellites.length; i++)
            _chip(slide.satellites[i], angle * 0.5 + i * 2 * math.pi / slide.satellites.length, size * 0.43),
          // Floating glass tile with the navy icon
          Transform.translate(
            offset: Offset(0, bob),
            child: GlassCard(
              radius: tile * 0.3,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: tile,
                height: tile,
                child: Center(
                  child: NeonGradient(
                    colors: GlassTheme.accentGradient,
                    child: Icon(slide.icon, size: tile * 0.52, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, double angle, double radius) {
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: GlassCard(
        radius: 16,
        blur: 10,
        padding: const EdgeInsets.all(11),
        child: Icon(icon, size: 20, color: GlassTheme.navySoft),
      ),
    );
  }
}
