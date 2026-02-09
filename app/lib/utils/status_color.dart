import 'package:flutter/material.dart';

// Palestine-themed status colors
Color getStatusColor(String status) {
  final s = status.toLowerCase();
  
  // RED: Avoid, High Risk - Palestinian flag red
  if (s.contains('avoid') || s.contains('high') || s.contains('very high')) {
    return const Color(0xFFCE1126);
  }
  
  // GREEN: Safe, Low Risk - Palestinian flag green
  if (s.contains('safe') || s.contains('low')) {
    return const Color(0xFF007A3D);
  }
  
  // AMBER: Caution, Medium
  if (s.contains('caution') || s.contains('medium') || s.contains('mid')) {
    return const Color(0xFFE6A817);
  }

  // Default - muted grey
  return const Color(0xFF9E9E9E);
}