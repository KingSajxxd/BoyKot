import 'package:flutter/material.dart';

import 'brand_logo_block.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.category,
    required this.brands,
    required this.onBrandTap,
  });

  final String category;
  final List<dynamic> brands;
  final ValueChanged<dynamic> onBrandTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: brands.length,
          itemBuilder: (context, index) => BrandLogoBlock(
            item: brands[index],
            onTap: () => onBrandTap(brands[index]),
          ),
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.grey.shade200, indent: 20, endIndent: 20),
      ],
    );
  }
}
