import 'package:flutter/material.dart';

class AppTheme {

  // Colores base
  static const primaryColor = Color(0xFFD35400); // Tono cálido / panadería
  static const secondaryColor = Color(0xFF2C3E50); // Tono corporativo oscuro


  // Colores semánticos 
  static const successColor = Color(0xFF27AE60);   // Verde (Para pagos exitosos y stock alto)
  static const errorColor = Color(0xFFE74C3C);     // Rojo (Para eliminar, cancelar, sin stock)
  static const warningColor = Color(0xFFF39C12);   // Naranja (Para el multiplicador y alertas)
  static const infoColor = Color(0xFF2980B9);      // Azul (Para retiro en local y datos)
  static const highlightColor = Color(0xFF3F51B5); // Índigo (Especial para destacar la Factura)
  static const businessColor = Color(0xFF00796B);  // Verde azulado (Especial para clientes empresas)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor, 
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}