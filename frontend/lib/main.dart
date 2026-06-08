import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'E-commerce App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: AppColors.steelBlue,
            secondary: AppColors.skyBlue,
            surface: AppColors.white,
            background: AppColors.background,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: AppColors.textPrimary,
            onSurface: AppColors.textPrimary,
            onBackground: AppColors.textPrimary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.dmSansTextTheme().copyWith(
            displayLarge: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            displayMedium: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.dmSans(color: AppColors.textPrimary),
            bodyMedium: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.steelBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.sand.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          dividerColor: AppColors.divider,
          cardColor: AppColors.white,
          cardTheme: CardThemeData(
            color: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}