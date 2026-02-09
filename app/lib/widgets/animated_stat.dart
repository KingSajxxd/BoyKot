import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AnimatedStat extends StatelessWidget {
  const AnimatedStat({
    super.key,
    required this.targetValue,
    required this.fontSize,
    required this.color,
  });

  final int targetValue;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: targetValue),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) => Text(
        NumberFormat('#,###').format(value),
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
          height: 1.0,
          letterSpacing: -1,
        ),
      ),
    );
  }
}
