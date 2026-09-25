import 'package:flutter/material.dart';

/// App-wide light, official palette: soft grey background, white cards and a single navy accent.
/// Status colours are deliberately muted so screens stay calm rather than colourful.
class AppColors {
  static const Color primary        = Color(0xFF1F3A68); // official navy (the one accent)
  static const Color accent         = Color(0xFF3A5A8C); // lighter navy, for gradients/highlights
  static const Color dark           = Color(0xFF1A1F2B); // primary text
  static const Color secondaryLabel = Color(0xFF6B7280); // secondary text
  static const Color background     = Color(0xFFF5F6F8); // screen background
  static const Color cardBg         = Color(0xFFFFFFFF); // cards
  static const Color success        = Color(0xFF2E7D5B); // muted green
  static const Color warning        = Color(0xFFB7791F); // muted amber
  static const Color danger         = Color(0xFFB83A3A); // muted red
  static const Color divider        = Color(0xFFE5E7EB);
}
