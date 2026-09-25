import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../signup_page.dart';
import '../../theme/glass_theme.dart';
import '../../theme/app_colors.dart';

class _TermsSection {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _TermsSection(this.icon, this.color, this.title, this.body);
}

/// Terms & Privacy agreement shown before sign up . Sections are frosted cards; a navy bar
/// tracks reading progress, and agreeing unlocks once the user has scrolled to the end.
class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> with SingleTickerProviderStateMixin {
  static const _accent = GlassTheme.accentGradient;

  static const _sections = [
    _TermsSection(
      CupertinoIcons.hand_thumbsup_fill,
      GlassTheme.navy,
      'Acceptance of Terms',
      'By accessing and using GovServiceNav, you agree to comply with these terms. This platform provides digital guidance, application drafting, and submission tracking for official government procedures.',
    ),
    _TermsSection(
      CupertinoIcons.person_crop_rectangle_fill,
      GlassTheme.navy,
      'Accuracy of Citizen Information',
      'You agree that all personal details, National ID numbers, and uploaded verification documents provided through this platform are authentic, current, and legally valid. Submitting fraudulent documents is subject to legal action under applicable laws.',
    ),
    _TermsSection(
      CupertinoIcons.lock_shield_fill,
      GlassTheme.navy,
      'Privacy & Data Handling',
      'Your data is securely stored and processed solely for verifying application eligibility and completing government procedures. Authorized Verifying Officers will inspect submitted evidence to process your requests.',
    ),
    _TermsSection(
      CupertinoIcons.sparkles,
      GlassTheme.navy,
      'AI Navigator Guidance',
      'Our AI Navigator provides automated procedure checklists and eligibility screening. While designed for accuracy, final approval of applications, fee schedules, and appointments rests with the responsible government department.',
    ),
    _TermsSection(
      CupertinoIcons.creditcard_fill,
      GlassTheme.navy,
      'Fee Payments & Installments',
      'Fees are calculated from official department schedules. Installment plans must be paid by each due date; an application whose installment is not paid on time is cancelled automatically. Processed fees are subject to department refund regulations.',
    ),
  ];

  final ScrollController _scroll = ScrollController();
  late final AnimationController _entrance;
  double _readProgress = 0;
  bool _reachedEnd = false;
  bool _hasAgreed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _scroll.addListener(_onScroll);
    // Short screens may show everything without scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final progress = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    setState(() {
      _readProgress = progress;
      if (progress >= 0.98) _reachedEnd = true;
    });
  }

  void _navigateToSignup() {
    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => const SignUpPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _animated(0, _buildHeader()),
                    const SizedBox(height: 20),
                    for (var i = 0; i < _sections.length; i++)
                      _animated(i + 1, _buildSectionCard(i + 1, _sections[i])),
                    _animated(
                      _sections.length + 1,
                      const Text(
                        'Last updated: August 2026',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: GlassTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              _buildAgreementBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.chevron_left, color: GlassTheme.navy),
                )
              else
                const SizedBox(width: 48),
              const Expanded(
                child: Text(
                  'Terms & Privacy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: GlassTheme.ink),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          // Neon reading-progress bar
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _readProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _accent),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: GlassTheme.navy.withValues(alpha: 0.2), blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Staggered fade + rise for the header and each card
  Widget _animated(int index, Widget child) {
    final start = (index * 0.1).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: _accent, begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: GlassTheme.navy.withValues(alpha: 0.25), blurRadius: 14)],
            ),
            child: const Icon(CupertinoIcons.checkmark_shield_fill, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you begin',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: GlassTheme.ink, letterSpacing: -0.3),
                ),
                SizedBox(height: 4),
                Text(
                  'Please read the GovServiceNav Terms of Service & Privacy Agreement.',
                  style: TextStyle(fontSize: 13, color: GlassTheme.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(int number, _TermsSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: section.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: section.color.withValues(alpha: 0.5)),
                boxShadow: [BoxShadow(color: section.color.withValues(alpha: 0.35), blurRadius: 12)],
              ),
              child: Icon(section.icon, color: section.color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. ${section.title}',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: GlassTheme.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(section.body, style: const TextStyle(fontSize: 13.5, color: GlassTheme.textMuted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementBar() {
    final canAgree = _reachedEnd;
    final canContinue = canAgree && _hasAgreed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: canAgree
                  ? GestureDetector(
                      key: const ValueKey('agree'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _hasAgreed = !_hasAgreed),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: _hasAgreed ? const LinearGradient(colors: _accent) : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _hasAgreed ? Colors.transparent : GlassTheme.textMuted,
                                width: 2,
                              ),
                              boxShadow: _hasAgreed
                                  ? [BoxShadow(color: GlassTheme.navy.withValues(alpha: 0.25), blurRadius: 8)]
                                  : [],
                            ),
                            child: _hasAgreed ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms of Service and Privacy Policy.',
                              style: TextStyle(fontSize: 14, color: GlassTheme.ink, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      key: const ValueKey('scroll'),
                      children: [
                        const Icon(CupertinoIcons.arrow_down_circle, color: GlassTheme.textMuted, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Scroll to the end to continue (${(_readProgress * 100).round()}% read)',
                            style: const TextStyle(fontSize: 14, color: GlassTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            NeonButton(
              label: 'Agree & Continue',
              icon: CupertinoIcons.arrow_right,
                            onPressed: canContinue ? _navigateToSignup : null,
            ),
          ],
        ),
      ),
    );
  }
}
