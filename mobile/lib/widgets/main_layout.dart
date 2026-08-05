import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_drawer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final bool isAuthenticated;
  final Color? backgroundColor;

  const MainLayout({
    super.key,
    required this.child,
    this.isAuthenticated = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      drawer: isMobile ? AppDrawer(isAuthenticated: isAuthenticated) : null,
      body: SafeArea(
        child: child,
      ),
    );
  }
}
