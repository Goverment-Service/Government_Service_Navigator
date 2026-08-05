import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import '../widgets/status_tracker_card.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import '../widgets/main_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return MainLayout(
      isAuthenticated: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Header Profile Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isMobile) ...[
                          Builder(
                            builder: (context) {
                              return IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              );
                            }
                          ),
                          const SizedBox(width: 8),
                        ],
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                          'Good Morning,',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Citizen',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'logout') {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      offset: const Offset(0, 50),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.secondaryColor,
                        child: Icon(Icons.person, color: AppTheme.primaryBlue),
                      ),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.redAccent, size: 20),
                              SizedBox(width: 12),
                              Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for services (e.g., Passport)',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: const Icon(
                      Icons.mic,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Access Categories
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    CategoryCard(
                      title: 'Health &\nMedical',
                      icon: Icons.local_hospital,
                      onTap: () {},
                    ),
                    CategoryCard(
                      title: 'Transport &\nDriving',
                      icon: Icons.directions_car,
                      onTap: () {},
                    ),
                    CategoryCard(
                      title: 'Housing &\nProperty',
                      icon: Icons.house,
                      onTap: () {},
                    ),
                    CategoryCard(
                      title: 'Taxes &\nRevenue',
                      icon: Icons.account_balance_wallet,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Applications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Applications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(onPressed: () {}, child: const Text('See All')),
                  ],
                ),
                const SizedBox(height: 12),
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
          ),
        ),
    );
  }
}
