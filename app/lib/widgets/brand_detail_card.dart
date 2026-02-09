import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/status_color.dart';

class BrandDetailCard extends StatelessWidget {
  const BrandDetailCard({
    super.key,
    required this.item,
    this.isModal = false,
    this.brandMap,
  });

  final dynamic item;
  final bool isModal;
  final Map<String, dynamic>? brandMap;

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(item['status']);
    final isAvoid = item['status']?.toString().toLowerCase().contains('avoid') ?? false;
    final alternatives = item['alternatives'] != null
        ? (item['alternatives'] as List)
        : <dynamic>[];
    final subbrands =
        item['subbrands'] != null ? (item['subbrands'] as List) : <dynamic>[];

    return Container(
      margin: isModal ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isModal ? 0 : 20),
        border: isModal 
            ? null 
            : Border.all(
                color: isAvoid 
                    ? const Color(0xFFCE1126).withOpacity(0.15) 
                    : Colors.grey.shade100,
                width: isAvoid ? 1.5 : 1,
              ),
        boxShadow: isModal
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Logo container
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: item['logo_asset'] != null
                      ? Image.asset(
                          item['logo_asset'],
                          errorBuilder: (c, e, s) => Icon(
                            Icons.business_rounded,
                            color: Colors.grey.shade300,
                            size: 28,
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          color: Colors.grey.shade300,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Name & Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (item['category'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item['category'],
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['status'].toString().toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.shade100),

          // --- DESCRIPTION ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              item['description'] ?? 'No description available.',
              style: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // --- SUB-BRANDS ---
          if (subbrands.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'INCLUDES / RELATED BRANDS',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subbrands
                        .map<Widget>(
                          (sub) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              sub.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          // --- ALTERNATIVES ---
          if (alternatives.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF007A3D).withOpacity(0.05),
                    const Color(0xFF007A3D).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(isModal ? 0 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A3D).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Color(0xFF007A3D),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ETHICAL ALTERNATIVES',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF007A3D),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: alternatives.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final altName = alternatives[index].toString();
                        final altItem = brandMap?[altName.toLowerCase()];
                        return _buildAlternativeBlock(altName, altItem);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlternativeBlock(String name, dynamic item) {
    final hasLogo = item != null && item['logo_asset'] != null;

    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF007A3D).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007A3D).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: hasLogo
                  ? Image.asset(
                      item['logo_asset'],
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF007A3D),
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF007A3D),
                      size: 28,
                    ),
            ),
          ),
          
          // Name Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF007A3D).withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(13),
              ),
            ),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}