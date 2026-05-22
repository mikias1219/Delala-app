import 'package:flutter/material.dart';
import '../../properties/presentation/properties_screen.dart';
import '../../workers/presentation/workers_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class ShellDestination {
  const ShellDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

List<ShellDestination> destinationsForRole(String role) {
  const properties = ShellDestination(
    id: 'properties',
    label: 'Homes',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    screen: PropertiesScreen(),
  );
  const workers = ShellDestination(
    id: 'workers',
    label: 'Workers',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    screen: WorkersScreen(),
  );
  const profile = ShellDestination(
    id: 'profile',
    label: 'Account',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    screen: ProfileScreen(),
  );

  switch (role) {
    case 'owner':
      return [properties, profile];
    case 'worker':
      return [workers, profile];
    case 'employer':
      return [workers, properties, profile];
    case 'admin':
      return [properties, workers, profile];
    case 'renter':
    default:
      return [properties, workers, profile];
  }
}
