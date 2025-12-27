import 'package:flutter/material.dart';

/// Cores do aplicativo
class AppColors {
  // Cores Primárias
  static const Color primary = Color(0xFF3F51B5); // Indigo
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color primaryLight = Color(0xFFC5CAE9);

  // Cores Secundárias
  static const Color secondary = Color(0xFFFFC107); // Amber
  static const Color secondaryDark = Color(0xFFFFA000);
  static const Color secondaryLight = Color(0xFFFFECB3);

  // Cores de Estado
  static const Color success = Color(0xFF4CAF50); // Verde
  static const Color warning = Color(0xFFFF9800); // Laranja
  static const Color error = Color(0xFFF44336); // Vermelho
  static const Color info = Color(0xFF2196F3); // Azul

  // Cores de Texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Cores de Fundo
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);

  // Cores Específicas do App
  static const Color profit = Color(0xFF4CAF50); // Verde para lucro
  static const Color cost = Color(0xFFF44336); // Vermelho para custo
  static const Color stock = Color(0xFF2196F3); // Azul para estoque
  static const Color stockLow = Color(0xFFFF9800); // Laranja para estoque baixo
  static const Color stockOut = Color(0xFFF44336); // Vermelho para sem estoque

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
