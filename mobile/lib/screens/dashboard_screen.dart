import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

import '../widgets/dashboard/home_dashboard_tab.dart';
import '../widgets/dashboard/services_tab.dart';
import '../widgets/dashboard/applications_tab.dart';
import '../widgets/dashboard/profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  final String userEmail;

  const DashboardScreen({
    super.key,
    required this.token,
    required this.userEmail,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    HomeDashboardTab(token: widget.token),
    ServicesTab(token: widget.token),
    ApplicationsTab(token: widget.token, userEmail: widget.userEmail),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: CupertinoTabBar(
            currentIndex: _currentIndex,
            backgroundColor: AppColors.cardBg,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.secondaryLabel,
            border: null,
            iconSize: 24,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                activeIcon: Icon(CupertinoIcons.house_fill),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.briefcase),
                activeIcon: Icon(CupertinoIcons.briefcase_fill),
                label: 'Services',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.doc_text),
                activeIcon: Icon(CupertinoIcons.doc_text_fill),
                label: 'Applications',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                activeIcon: Icon(CupertinoIcons.person_fill),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}