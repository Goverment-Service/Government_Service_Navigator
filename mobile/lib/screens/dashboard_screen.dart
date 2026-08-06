import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../widgets/category_card.dart';
import '../widgets/status_tracker_card.dart';
import 'login_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS systemGray6
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLargeHeader(context),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search services',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  placeholderStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                  ),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 6),
                  onSubmitted: (_) {},
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader(
                  context, 'Popular Services', null),
              const SizedBox(height: 12),
              _buildServicesGrid(),
              const SizedBox(height: 32),

              _buildSectionHeader(context, 'Recent Applications', 'See All'),
              const SizedBox(height: 12),
              _buildRecentApplications(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning,',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Citizen 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Avatar / Sign In
          GestureDetector(
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String? actionLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          if (actionLabel != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () {},
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      {'title': 'Driving Licence\nRenewal', 'icon': Icons.badge_outlined},
      {'title': 'Business\nRegistration', 'icon': Icons.storefront_outlined},
      {'title': 'Land Permit\nApplication', 'icon': Icons.landscape_outlined},
      {'title': 'Passport\nApplication', 'icon': Icons.flight_takeoff_outlined},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.0,
        children: services.map((s) {
          return CategoryCard(
            title: s['title'] as String,
            icon: s['icon'] as IconData,
            onTap: () {
              _showServiceSheet(context, s['title'] as String);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentApplications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: const [
          StatusTrackerCard(
            applicationName: 'Passport Renewal',
            status: 'Pending Review',
            date: 'Oct 24, 2023',
            icon: Icons.airplane_ticket,
          ),
          StatusTrackerCard(
            applicationName: 'Vehicle Registration',
            status: 'Action Required',
            date: 'Oct 15, 2023',
            icon: Icons.directions_car,
          ),
          StatusTrackerCard(
            applicationName: 'Business License',
            status: 'Approved',
            date: 'Sep 02, 2023',
            icon: Icons.store,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': CupertinoIcons.house_fill, 'label': 'Home'},
      {'icon': CupertinoIcons.doc_text_fill, 'label': 'Services'},
      {'icon': CupertinoIcons.clock_fill, 'label': 'History'},
      {'icon': CupertinoIcons.person_fill, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == _selectedTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        size: 22,
                        color: active
                            ? AppColors.primary
                            : const Color(0xFF8E8E93),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : const Color(0xFF8E8E93),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showServiceSheet(BuildContext context, String serviceName) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(serviceName.replaceAll('\n', ' ')),
        message: const Text(
            'Sign in to apply for this service and track your application.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Sign In to Apply'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Learn More'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
