import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/cajero_home_screen.dart';
import '../screens/repartidor_home_screen.dart';
import '../screens/admin_dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // 1. Pantalla de Selección de Rol / Login Inicial
      GoRoute(
        path: '/',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      // 2. Módulo del Cajero (Punto de Venta)
      GoRoute(
        path: '/cajero',
        builder: (context, state) => const CajeroHomeScreen(),
      ),
      // 3. Módulo del Repartidor (Despachos y Envíos)
      GoRoute(
        path: '/repartidor',
        builder: (context, state) => const RepartidorHomeScreen(),
      ),
      // 4. Módulo de Administración (Dashboard de Métricas e Inventario)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Ruta no encontrada')),
    ),
  );
}