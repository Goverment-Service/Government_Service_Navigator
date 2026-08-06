import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mobile/screens/index/loading_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // iOS-style light status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Government Service Navigator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // iOS-style page transitions throughout
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: _IOSScrollBehavior(),
          child: child!,
        );
      },
      home: const LoadingPage(),
    );
  }
}

/// Gives the entire app native iOS momentum-style scrolling physics
class _IOSScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}