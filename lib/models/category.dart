import 'package:flutter/material.dart';

/// أنواع الخدمات في التطبيق.
enum PlaceCategory {
  pharmacy('pharmacy', 'صيدليات', Icons.local_pharmacy, Color(0xFF2E7D32)),
  supermarket('supermarket', 'سوبر ماركت', Icons.shopping_cart, Color(0xFFEF6C00)),
  doctor('doctor', 'دكاترة وعيادات', Icons.medical_services, Color(0xFFC62828)),
  school('school', 'مدارس', Icons.school, Color(0xFF1565C0)),
  tutoring('tutoring', 'سناتر دروس', Icons.menu_book, Color(0xFF6A1B9A)),
  crafts('crafts', 'أعمال وحرف', Icons.handyman, Color(0xFF5D4037)),
  publicFigure('public_figure', 'شخصيات عامة', Icons.account_balance, Color(0xFF00838F)),
  company('company', 'شركات', Icons.business, Color(0xFF37474F));

  const PlaceCategory(this.id, this.label, this.icon, this.color);

  /// القيمة اللي بتتخزن في قاعدة البيانات.
  final String id;

  /// الاسم اللي بيظهر للمستخدم.
  final String label;
  final IconData icon;
  final Color color;

  static PlaceCategory fromId(String id) {
    return PlaceCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => PlaceCategory.pharmacy,
    );
  }
}
