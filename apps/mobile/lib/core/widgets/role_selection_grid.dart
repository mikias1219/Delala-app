import 'package:flutter/material.dart';
import '../constants/user_roles.dart';

class RoleSelectionGrid extends StatelessWidget {
  const RoleSelectionGrid({
    super.key,
    required this.selectedRole,
    required this.onSelected,
    this.enabled = true,
  });

  final String selectedRole;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: registrationRoles.map((role) {
        final selected = selectedRole == role.id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onSelected(role.id) : null,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? role.color.withValues(alpha: 0.12)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? role.color : Theme.of(context).dividerColor,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(role.icon, color: role.color, size: 28),
                  const Spacer(),
                  Text(
                    role.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? role.color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
