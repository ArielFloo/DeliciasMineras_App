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

  final client = Supabase.instance.client;
  try {
    // Intentamos consultar la tabla de productos sin esquema (porque ya configuramos el search_path)
    final data = await client.schema('deliciasmineras').from('producto').select().limit(1);
    print("¡CONEXIÓN EXITOSA! Datos obtenidos: $data");
  } catch (e) {
    print("ERROR DE CONEXIÓN: $e");
  }
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