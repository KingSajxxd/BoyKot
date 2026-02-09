import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DetailTag extends StatelessWidget {
  const DetailTag({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  final int value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const redWords = ['killed', 'attacked', 'starved', 'injured', 'death'];
    final words = label.split(' ');
    final hasRedWord = words.any((w) => redWords.contains(w.toLowerCase()));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasRedWord 
            ? const Color(0xFFCE1126).withOpacity(0.04) 
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasRedWord 
              ? const Color(0xFFCE1126).withOpacity(0.15) 
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: hasRedWord 
                  ? const Color(0xFFCE1126).withOpacity(0.6) 
                  : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
          ],
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(seconds: 2),
            curve: Curves.easeOutExpo,
            builder: (context, val, child) => Text(
              NumberFormat('#,###').format(val),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: hasRedWord 
                  ? const Color(0xFFCE1126).withOpacity(0.8) 
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
