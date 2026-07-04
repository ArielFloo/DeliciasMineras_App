import 'package:flutter/material.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';

void main() {
  runApp(const DeliciasMinerasApp());
}

class DeliciasMinerasApp extends StatelessWidget {
  const DeliciasMinerasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Delicias Mineras',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}