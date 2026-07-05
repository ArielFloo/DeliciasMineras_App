import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==========================================
  // COLORES BASE
  // ==========================================
  static const primaryColor = Color(0xFFD35400); 
  static const secondaryColor = Color(0xFF2C3E50); 

  // ==========================================
  // COLORES SEMÁNTICOS
  // ==========================================
  static const successColor = Color(0xFF27AE60);   
  static const errorColor = Color(0xFFE74C3C);     
  static const warningColor = Color(0xFFF39C12);   
  static const infoColor = Color(0xFF2980B9);      
  static const highlightColor = Color(0xFF3F51B5); 
  static const businessColor = Color(0xFF00796B);  

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // TIPOGRAFÍA GLOBAL CENTRALIZADA
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: GoogleFonts.poppinsTextTheme(),

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