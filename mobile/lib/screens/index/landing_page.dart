import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../login_page.dart';
import 'index.dart';
import '../../theme/glass_theme.dart';
import '../../theme/app_colors.dart';
import 'slide_show.dart';

/// Onboarding slideshow: calm light backdrop, floating glass illustrations and one navy accent throughout.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _float;
  int _currentPage = 0;

  static const List<OnboardSlide> _slides = [
    OnboardSlide(
      icon: CupertinoIcons.sparkles,
      satellites: [CupertinoIcons.search, CupertinoIcons.chat_bubble_text_fill, CupertinoIcons.lightbulb_fill],
      title: 'AI-Powered\nGuidance',
      subtitle: 'Describe your need in plain language. We match it to the right government procedure instantly.',
    ),
    OnboardSlide(
      icon: CupertinoIcons.doc_checkmark_fill,
      satellites: [CupertinoIcons.cloud_upload_fill, CupertinoIcons.person_crop_rectangle_fill, CupertinoIcons.paperclip],
      title: 'Apply Without\nthe Hassle',
      subtitle: 'Fill in forms and upload your documents from your phone — no queues, no paperwork.',
    ),
    OnboardSlide(
      icon: CupertinoIcons.creditcard_fill,
      satellites: [CupertinoIcons.building_2_fill, CupertinoIcons.calendar, CupertinoIcons.lock_shield_fill],
      title: 'Pay Your\nWay',
      subtitle: 'Pay online by card, by bank transfer, or split the fee into installments with due-date reminders.',
    ),
    OnboardSlide(
      icon: CupertinoIcons.bell_fill,
      satellites: [CupertinoIcons.checkmark_seal_fill, CupertinoIcons.clock_fill, CupertinoIcons.envelope_fill],
      title: 'Live Status\nUpdates',
      subtitle: 'Get notified the moment an officer reviews, approves or requests changes to your application.',
    ),
  ];

  bool get _isLast => _currentPage == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _float.dispose();
    super.dispose();
  }

  void _next() {
    if (!_isLast) {
      _pageController.nextPage(duration: const Duration(milliseconds: 550), curve: Curves.easeInOutCubic);
    } else {
      _goToDashboard();
    }
  }

  void _skip() {
    _pageController.animateToPage(_slides.length - 1,
        duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => const IndexPage()));
  }

  void _signIn() {
    Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const LoginPage()));
  }

  /// Current scroll position in pages (e.g. 1.4 while swiping from slide 2 to 3)
  double get _page =>
      _pageController.hasClients && _pageController.position.haveDimensions
          ? _pageController.page ?? _currentPage.toDouble()
          : _currentPage.toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _pageController,
        builder: (context, _) {
          return AuroraBackdrop(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _slides.length,
                      itemBuilder: (_, i) => SlideView(
                        slide: _slides[i],
                        pageOffset: (i - _page).clamp(-1.0, 1.0),
                        float: _float,
                      ),
                    ),
                  ),
                  _buildBottomControls(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
      child: Row(
        children: [
          GlassCard(
            radius: 14,
            blur: 10,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              '${_currentPage + 1} / ${_slides.length}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: GlassTheme.navy),
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: _isLast ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: TextButton(
              onPressed: _isLast ? null : _skip,
              child: const Text('Skip', style: TextStyle(color: GlassTheme.textMuted, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _signIn,
            child: GlassCard(
              radius: 20,
              blur: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text('Sign In', style: TextStyle(color: GlassTheme.navy, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Neon dots: the active one stretches into a glowing pill
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final closeness = (1 - (i - _page).abs()).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8 + 22 * closeness,
                height: 8,
                decoration: BoxDecoration(
                  color: Color.lerp(AppColors.divider, GlassTheme.navy, closeness),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: closeness > 0.5
                      ? [BoxShadow(color: GlassTheme.navy.withValues(alpha: 0.25 * closeness), blurRadius: 6)]
                      : [],
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          NeonButton(
            label: _isLast ? 'Get Started' : 'Continue',
            icon: CupertinoIcons.arrow_right,
            onPressed: _next,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account?  ', style: TextStyle(fontSize: 14, color: GlassTheme.textMuted)),
              GestureDetector(
                onTap: _signIn,
                child: Text('Sign In',
                    style: TextStyle(fontSize: 14, color: GlassTheme.navy, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
