import 'package:flutter/material.dart';

class AppColors {
  // Bank of America Brand Colors
  static const Color primaryBlue = Color(0xFF012169); // Bank of America blue
  static const Color darkBlue = Color(0xFF000D2D);    // Darker variant
  static const Color lightBlue = Color(0xFF1A3A8A);   // Lighter variant
  
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  
  // Grays for UI elements
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE0E0E0);
  static const Color gray300 = Color(0xFFBDBDBD);
  static const Color gray400 = Color(0xFF9E9E9E);
  static const Color gray500 = Color(0xFF757575);
  static const Color gray600 = Color(0xFF616161);
  static const Color gray700 = Color(0xFF424242);
  static const Color gray800 = Color(0xFF212121);
  
  // Semantic colors
  static const Color success = Color(0xFF2E7D32);  // Professional green
  static const Color error = Color(0xFFC62828);    // Professional red
  static const Color warning = Color(0xFFF57C00);  // Professional orange
  static const Color info = primaryBlue;
  
  // Gradient for premium feel
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, darkBlue],
  );
  
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, lightBlue],
  );
}