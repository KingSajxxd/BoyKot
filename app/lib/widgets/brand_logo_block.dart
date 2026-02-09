import 'package:flutter/material.dart';

import '../utils/status_color.dart';

class BrandLogoBlock extends StatelessWidget {
  const BrandLogoBlock({
    super.key,
    required this.item,
    required this.onTap,
  });

  final dynamic item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(item['status']);
    final isAvoid = item['status']?.toString().toLowerCase().contains('avoid') ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAvoid 
                  ? const Color(0xFFCE1126).withOpacity(0.2) 
                  : Colors.grey.shade100,
              width: isAvoid ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            children: [
              // Logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: item['logo_asset'] != null
                      ? Image.asset(
                          item['logo_asset'],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.business_rounded,
                            color: Colors.grey.shade300,
                            size: 32,
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          size: 32,
                          color: Colors.grey.shade300,
                        ),
                ),
              ),
              
              // Status indicator
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.35),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ),
              
              // Avoid overlay indicator
              if (isAvoid)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCE1126).withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(17),
                        bottomRight: Radius.circular(17),
                      ),
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      size: 14,
                      color: Color(0xFFCE1126),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
