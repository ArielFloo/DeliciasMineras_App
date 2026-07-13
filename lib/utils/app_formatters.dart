import 'package:flutter/services.dart';

class AppFormatters {
  // ==========================================
  // FORMATEO DE DINERO
  // ==========================================
  static String formatearDinero(int monto) {
    return monto.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    );
  }

  // ==========================================
  // VALIDADOR MATEMÁTICO DE RUT (Algoritmo Módulo 11)
  // ==========================================
  static bool validarRut(String rut) {
    // 1. Limpiamos el texto dejando solo números y la letra K
    String rutLimpio = rut.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    if (rutLimpio.length < 2) return false;

    // 2. Separamos el cuerpo del dígito verificador (DV)
    String dv = rutLimpio.substring(rutLimpio.length - 1);
    String cuerpo = rutLimpio.substring(0, rutLimpio.length - 1);

    // 3. Aplicamos el algoritmo Módulo 11
    int suma = 0;
    int multiplicador = 2;

    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador = multiplicador < 7 ? multiplicador + 1 : 2;
    }

    int dvEsperado = 11 - (suma % 11);
    String dvCalculado;
    
    if (dvEsperado == 11) {
      dvCalculado = '0';
    } else if (dvEsperado == 10) {
      dvCalculado = 'K';
    } else {
      dvCalculado = dvEsperado.toString();
    }

    return dv == dvCalculado;
  }
}

// ==========================================
// FORMATEADOR VISUAL EN VIVO PARA TEXTFIELDS
// ==========================================
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Si el usuario borra todo, lo dejamos pasar
    if (newValue.text.isEmpty) return newValue;

    // Quitamos cualquier caracter que no sea número o K
    String text = newValue.text.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();
    if (text.isEmpty) return newValue.copyWith(text: '');

    String rutFormat = '';
    
    // Extraemos el DV y le ponemos el guion
    if (text.length > 1) {
      rutFormat = '-${text.substring(text.length - 1)}';
      text = text.substring(0, text.length - 1);
    } else {
      return newValue.copyWith(text: text);
    }

    // Agregamos los puntos cada 3 números de derecha a izquierda
    while (text.length > 3) {
      rutFormat = '.${text.substring(text.length - 3)}$rutFormat';
      text = text.substring(0, text.length - 3);
    }
    rutFormat = text + rutFormat;

    // Retornamos el nuevo valor con el cursor al final
    return TextEditingValue(
      text: rutFormat,
      selection: TextSelection.collapsed(offset: rutFormat.length),
    );
  }
}