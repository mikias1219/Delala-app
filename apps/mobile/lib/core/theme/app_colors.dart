import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xFF0D6E4F);
  static const seedDark = Color(0xFF084A35);
  static const surface = Color(0xFFF8FAF9);
  static const card = Colors.white;
  static const textMuted = Color(0xFF5C6B66);
  static const border = Color(0xFFE2E8E5);
  static const error = Color(0xFFC62828);
  static const success = Color(0xFF2E7D32);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D6E4F), Color(0xFF1B8A6B)],
  );
}
