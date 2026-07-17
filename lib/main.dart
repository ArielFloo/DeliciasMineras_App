import 'package:flutter/material.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Supabase con las llaves
  await Supabase.initialize(
    url: 'https://jmuxeojoblyyskfgkmfn.supabase.co',
    anonKey: 'sb_publishable_J6YBDIB7BU9fXN9T8YdatQ_oI9C0WHW',
  );
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