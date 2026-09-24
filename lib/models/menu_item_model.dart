import 'package:flutter/material.dart';

enum MenuCategory {
  dashboard,
  masterData,
  pembelian,
  penerimaan,
  qcLab,
  finance,
  laporan,
  userAccess,
}

class SubMenuItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final String route;

  const SubMenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.badge,
    this.badgeColor,
    required this.route,
  });
}

class MenuGroupItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final MenuCategory category;
  final List<SubMenuItem> items;
  final bool isFeatured;

  const MenuGroupItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.category,
    required this.items,
    this.isFeatured = false,
  });
}

