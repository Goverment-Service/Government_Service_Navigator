import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../signup_page.dart'; 

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _hasAgreed = false;

  void _navigateToSignup() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (_) => const SignUpPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Terms Document Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GovServiceNav Terms of Service & Privacy Agreement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Last updated: August 2026',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                      Divider(height: 32, color: AppColors.divider),

                      _SectionTitle('1. Acceptance of Terms'),
                      _SectionBody(
                        'By accessing and using GovServiceNav, you agree to comply with these terms. This platform provides digital guidance, application drafting, and submission tracking for official government procedures.',
                      ),

                      _SectionTitle('2. Accuracy of Citizen Information'),
                      _SectionBody(
                        'You agree that all personal details, National ID numbers, and uploaded verification documents provided through this platform are authentic, current, and legally valid. Submitting fraudulent documents is subject to legal action under applicable laws.',
                      ),

                      _SectionTitle('3. Privacy & Data Handling'),
                      _SectionBody(
                        'Your data is securely stored and processed solely for verifying application eligibility and completing government procedures. Authorized Verifying Officers will inspect submitted evidence to process your requests.',
                      ),

                      _SectionTitle('4. AI Navigator Guidance'),
                      _SectionBody(
                        'Our AI Navigator provides automated procedure checklists and eligibility screening. While designed for accuracy, final approval of applications, fee schedules, and appointments rests with the responsible government department.',
                      ),

                      _SectionTitle('5. Fee Payments & Sandboxing'),
                      _SectionBody(
                        'Any permit or licence fees displayed are calculated based on official department schedules. Once an application is submitted for verification, processed fees are subject to department refund regulations.',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Agreement Bar & Action Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: const Border(
                  top: BorderSide(color: AppColors.divider, width: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Interactive Checkbox Row
                  GestureDetector(
                    onTap: () => setState(() => _hasAgreed = !_hasAgreed),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _hasAgreed,
                            onChanged: (val) {
                              setState(() {
                                _hasAgreed = val ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'I have read and agree to the Terms of Service and Privacy Policy.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.dark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Agree & Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasAgreed
                            ? AppColors.primary
                            : AppColors.secondaryLabel.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      // Disabled if checkbox is unchecked
                      onPressed: _hasAgreed ? _navigateToSignup : null,
                      child: const Text(
                        'Agree & Continue',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widgets for formatted text
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.secondaryLabel,
        height: 1.45,
      ),
    );
  }
}