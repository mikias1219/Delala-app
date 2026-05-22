import 'package:flutter/material.dart';

class UserRoleInfo {
  const UserRoleInfo({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

/// Public roles available at registration (admin excluded).
const registrationRoles = [
  UserRoleInfo(
    id: 'renter',
    label: 'Renter',
    description: 'Find verified homes',
    icon: Icons.home_work_outlined,
    color: Color(0xFF0D6E4F),
  ),
  UserRoleInfo(
    id: 'owner',
    label: 'Property owner',
    description: 'List & manage rentals',
    icon: Icons.apartment_outlined,
    color: Color(0xFF1565C0),
  ),
  UserRoleInfo(
    id: 'worker',
    label: 'Domestic worker',
    description: 'Offer your services',
    icon: Icons.cleaning_services_outlined,
    color: Color(0xFF6A1B9A),
  ),
  UserRoleInfo(
    id: 'employer',
    label: 'Employer',
    description: 'Hire trusted help',
    icon: Icons.business_center_outlined,
    color: Color(0xFFE65100),
  ),
];

UserRoleInfo? roleById(String id) {
  for (final r in registrationRoles) {
    if (r.id == id) return r;
  }
  if (id == 'admin') {
    return const UserRoleInfo(
      id: 'admin',
      label: 'Admin',
      description: 'Platform admin',
      icon: Icons.admin_panel_settings_outlined,
      color: Color(0xFF37474F),
    );
  }
  return null;
}

String roleLabel(String role) => roleById(role)?.label ?? role;
