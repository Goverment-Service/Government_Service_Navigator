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
    return MainLayout(
      isAuthenticated: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () {
                            if (Scaffold.of(context).hasDrawer) {
                              Scaffold.of(context).openDrawer();
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GovServiceNav',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
