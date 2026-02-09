import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';

class BoycottApp extends StatelessWidget {
  const BoycottApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Palestine-inspired color palette
    const primaryRed = Color(0xFFCE1126);      // Palestinian flag red
    const accentGreen = Color(0xFF007A3D);     // Palestinian flag green
    const deepBlack = Color(0xFF1A1A1A);       // Rich black for text
    const softWhite = Color(0xFFFAFAFA);       // Background white
    const cardWhite = Color(0xFFFFFFFF);       // Pure white for cards

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BoyKot',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: softWhite,
        primaryColor: primaryRed,
        colorScheme: ColorScheme.light(
          primary: primaryRed,
          secondary: accentGreen,
          surface: cardWhite,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: deepBlack,
        ),
        cardColor: cardWhite,
        dividerColor: Colors.grey.shade200,
        
        // Typography with Google Fonts
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.poppins(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: primaryRed,
            height: 1.0,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: deepBlack,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: deepBlack,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: deepBlack,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: deepBlack,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: deepBlack,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: deepBlack,
            height: 1.6,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade700,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          labelSmall: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.grey.shade500,
          ),
        ),
        
        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryRed, width: 2),
          ),
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade400,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
        ),
        
        // Card theme
        cardTheme: CardThemeData(
          color: cardWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        
        // Floating action button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

