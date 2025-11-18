import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.pureWhite, 
      onPrimary: AppColors.black, 
    ),

    scaffoldBackgroundColor: AppColors.black,

    textTheme: const TextTheme(
      titleMedium: TextStyle(fontSize: 20,color: AppColors.pureWhite)
    ),

  );
}