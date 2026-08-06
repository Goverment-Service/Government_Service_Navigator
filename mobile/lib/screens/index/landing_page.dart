import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../login_page.dart';
import 'index.dart';
import 'slide_show.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardSlide> _slides = [
    OnboardSlide(
      icon: CupertinoIcons.sparkles,
      bgColor: Color(0xFFEAF3FF),
      iconColor: Color(0xFF007AFF),
      title: 'AI-Powered\nGuidance',
      subtitle:
          'Describe your need in plain language. We match it to the right government procedure instantly.',
    ),
    OnboardSlide(
      icon: CupertinoIcons.doc_checkmark_fill,
      bgColor: Color(0xFFEAFBEE),
      iconColor: Color(0xFF34C759),
      title: 'Apply Without\nthe Hassle',
      subtitle:
          'Submit applications, upload documents and pay fees securely — all from your phone, no queues.',
    ),
    OnboardSlide(
      icon: CupertinoIcons.bell_fill,
      bgColor: Color(0xFFFFF4E5),
      iconColor: Color(0xFFFF9500),
      title: 'Live Status\nUpdates',
      subtitle:
          'Get notified the moment an officer reviews, approves or requests changes to your application.',
    ),
  ];

  bool get _isLast => _currentPage == _slides.length - 1;

  void _next() {
    if (!_isLast) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (_) => const IndexPage()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => SlideView(slide: _slides[i]),
              ),
            ),

            _BottomControls(
              pageCount: _slides.length,
              currentPage: _currentPage,
              isLast: _isLast,
              onNext: _next,
              onSignIn: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const LoginPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _BottomControls extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSignIn;

  const _BottomControls({
    required this.pageCount,
    required this.currentPage,
    required this.isLast,
    required this.onNext,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                width: active ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Continue / Get Started
          SizedBox(
            width: double.infinity,
            height: 54,
            child: CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              padding: EdgeInsets.zero,
              onPressed: onNext,
              child: Text(
                isLast ? 'Get Started' : 'Continue',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Sign In link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account?  ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
              GestureDetector(
                onTap: onSignIn,
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
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