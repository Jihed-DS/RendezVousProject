import 'package:flutter/material.dart';

class CategoryStyle {
  final IconData icon;
  final Color color;

  const CategoryStyle({required this.icon, required this.color});

  static const _map = {
    'Coiffure': CategoryStyle(icon: Icons.content_cut, color: Color(0xFFEC4899)),
    'Santé': CategoryStyle(icon: Icons.favorite_outline, color: Color(0xFF10B981)),
    'Consulting': CategoryStyle(icon: Icons.business_center_outlined, color: Color(0xFF3B82F6)),
    'Sport': CategoryStyle(icon: Icons.fitness_center, color: Color(0xFFF59E0B)),
    'Éducation': CategoryStyle(icon: Icons.school_outlined, color: Color(0xFF8B5CF6)),
    'Photographie': CategoryStyle(icon: Icons.camera_alt_outlined, color: Color(0xFF06B6D4)),
    'Juridique': CategoryStyle(icon: Icons.gavel_outlined, color: Color(0xFF64748B)),
  };

  static const _fallback = CategoryStyle(icon: Icons.category_outlined, color: Color(0xFF6B7280));

  static CategoryStyle of(String? categoryName) {
    if (categoryName == null) return _fallback;
    return _map[categoryName] ?? _fallback;
  }
}