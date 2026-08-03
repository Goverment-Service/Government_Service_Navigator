import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../widgets/service_card.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<ServiceItem> _popularServices = const [
    ServiceItem(
      icon: Icons.badge_outlined,
      label: 'Driving Licence\nRenewal',
    ),
    ServiceItem(
      icon: Icons.storefront_outlined,
      label: 'Business\nRegistration',
    ),
    ServiceItem(
      icon: Icons.landscape_outlined,
      label: 'Land Permit\nApplication',
    ),
    ServiceItem(
      icon: Icons.flight_takeoff_outlined,
      label: 'Passport\nApplication',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitNeed(String text) {
    if (text.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Looking into: "$text"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 28),
              _buildHero(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 32),
              _buildSectionTitle('Popular Services'),
              const SizedBox(height: 14),
              _buildServiceGrid(),
              const SizedBox(height: 32),
              _buildSectionTitle('Track Your Application'),
              const SizedBox(height: 14),
              _buildTrackCard(),
              const SizedBox(height: 32),
              _buildHowItWorks(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'GovServiceNav',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          icon: const Icon(Icons.person_outline, color: AppColors.dark),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us what you need.\nWe\u2019ll guide you there.',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Describe your situation in your own words — no forms, '
          'no jargon. We\u2019ll match it to the right government '
          'procedure for you.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dark.withOpacity(0.65),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _submitNeed,
              decoration: const InputDecoration(
                hintText: 'e.g. "I lost my driving licence"',
                border: InputBorder.none,
              ),
            ),
          ),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _submitNeed(_searchController.text),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      ),
    );
  }

  Widget _buildServiceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _popularServices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final service = _popularServices[index];
        return ServiceCard(
          service: service,
          onTap: () {
            // TODO: navigate to service detail / guided procedure
          },
        );
      },
    );
  }

  Widget _buildTrackCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFF3D8BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Have an active application?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check its live status and next steps.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: navigate to application tracker
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      ('1', 'Describe your need in plain language'),
      ('2', 'Our AI checks eligibility & required documents'),
      ('3', 'Submit your application & documents'),
      ('4', 'An officer reviews and approves it'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('How It Works'),
        const SizedBox(height: 14),
        ...steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    step.$1,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.$2,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.dark.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}