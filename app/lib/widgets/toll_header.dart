import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/number_utils.dart';
import 'animated_stat.dart';
import 'detail_tag.dart';

class TollHeader extends StatelessWidget {
  const TollHeader({super.key, required this.toll});

  final Map<String, dynamic> toll;

  @override
  Widget build(BuildContext context) {
    final killed = toInt(toll['killed']);
    final date = toll['last_update'] ?? 'Live';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFCE1126).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCE1126),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCE1126).withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'GAZA DEATH TOLL',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCE1126),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Main death toll number
          AnimatedStat(
            targetValue: killed,
            fontSize: 56,
            color: const Color(0xFFCE1126),
          ),
          const SizedBox(height: 8),
          
          // Last update
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.update_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                'Last update: $date',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Divider with icon
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 18,
                  color: Colors.grey.shade300,
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Statistics tags
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              DetailTag(
                value: toInt(toll['children']),
                label: 'children killed',
                icon: Icons.child_care_rounded,
              ),
              DetailTag(
                value: toInt(toll['women']),
                label: 'women killed',
                icon: Icons.woman_rounded,
              ),
              DetailTag(
                value: toInt(toll['injured']),
                label: 'injured',
                icon: Icons.personal_injury_rounded,
              ),
              DetailTag(
                value: toInt(toll['starved']),
                label: 'starved to death',
                icon: Icons.no_food_rounded,
              ),
              DetailTag(
                value: toInt(toll['aid_attacked']),
                label: 'attacked seeking aid',
                icon: Icons.healing_rounded,
              ),
              DetailTag(
                value: toInt(toll['medical']),
                label: 'medical workers',
                icon: Icons.medical_services_rounded,
              ),
              DetailTag(
                value: toInt(toll['press']),
                label: 'journalists',
                icon: Icons.campaign_rounded,
              ),
              DetailTag(
                value: toInt(toll['civil_defense']),
                label: 'first responders',
                icon: Icons.local_fire_department_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
