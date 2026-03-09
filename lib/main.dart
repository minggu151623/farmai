import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/design_system.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmAI Chẩn Đoán',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: FarmColors.background,
        fontFamily: GoogleFonts.roboto().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FarmColors.primary,
          brightness: Brightness.light,
          primary: FarmColors.primary,
          onPrimary: FarmColors.onPrimary,
          secondary: FarmColors.accent,
          onSecondary: FarmColors.onAccent,
          error: FarmColors.error,
          onError: Colors.white,
          surface: FarmColors.surface,
          onSurface: FarmColors.textPrimary,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: FarmTextStyles.heading1,
          displayMedium: FarmTextStyles.heading2,
          bodyLarge: FarmTextStyles.bodyLarge,
          bodyMedium: FarmTextStyles.bodyMedium,
          labelLarge: FarmTextStyles.button,
          labelSmall: FarmTextStyles.labelSmall,
        ),
        cardTheme: CardThemeData(
          color: FarmColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: FarmStyles.cardRadius,
            side: BorderSide(color: FarmColors.surfaceVariant),
          ),
          shadowColor: FarmColors.primary.withValues(alpha: 0.08),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: FarmTextStyles.heading3,
          iconTheme: const IconThemeData(color: FarmColors.textPrimary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: FarmStyles.buttonRadius,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: FarmStyles.buttonRadius,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
