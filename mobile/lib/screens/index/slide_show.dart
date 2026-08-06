import 'package:flutter/material.dart';

class OnboardSlide {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String title;
  final String subtitle;

  const OnboardSlide({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class SlideView extends StatefulWidget {
  final OnboardSlide slide;
  const SlideView({super.key, required this.slide});

  @override
  State<SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<SlideView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _rise;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.80, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _rise = Tween<Offset>(
            begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final blobSize = screenW * 0.60;
    final innerSize = blobSize * 0.55;
    final iconSize = innerSize * 0.48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _fade,
              child: _buildBlob(blobSize, innerSize, iconSize),
            ),
          ),
          const SizedBox(height: 52),

          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _rise,
              child: Text(
                widget.slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.10,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _rise,
              child: Text(
                widget.slide.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8E8E93),
                  height: 1.55,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double blobSize, double innerSize, double iconSize) {
    return SizedBox(
      width: blobSize,
      height: blobSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft ring
          Container(
            width: blobSize,
            height: blobSize,
            decoration: BoxDecoration(
              color: widget.slide.bgColor,
              shape: BoxShape.circle,
            ),
          ),
          // Inner solid circle
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: widget.slide.iconColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.slide.iconColor.withValues(alpha: 0.38),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: widget.slide.iconColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              widget.slide.icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
