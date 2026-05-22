import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workers/data/workers_api.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Not signed in'));
        }

        final role = roleById(user.role);
        final score = user.trustScore?['score'] ?? 50;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(gradient: AppColors.gradient),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          child: Icon(
                            role?.icon ?? Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName ?? 'Complete your profile',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (user.phone.isNotEmpty)
                          Text(
                            user.phone,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        if (role != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(role.label, style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Trust score',
                            value: '$score',
                            suffix: '/ 100',
                            icon: Icons.verified_user,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            label: 'Status',
                            value: user.status,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Account actions', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (user.role == 'worker')
              _ActionTile(
                icon: Icons.badge_outlined,
                title: 'Worker profile',
                subtitle: 'Skills, availability & bio (min 10 chars)',
                onTap: () => _setupWorkerProfile(context, ref),
              ),
            if (user.role == 'employer')
              _ActionTile(
                icon: Icons.work_outline,
                title: 'Post a job',
                subtitle: 'Hire verified domestic workers',
                onTap: () => _postJob(context, ref),
              ),
            if (user.role == 'renter')
              const _ActionTile(
                icon: Icons.home_outlined,
                title: 'Browse verified homes',
                subtitle: 'Only admin-verified listings are shown',
              ),
            if (user.role == 'owner')
              const _ActionTile(
                icon: Icons.apartment_outlined,
                title: 'Your listings',
                subtitle: 'New listings require admin verification',
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(currentUserProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setupWorkerProfile(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(workersApiProvider).upsertProfile(
            skills: ['cleaning', 'cooking'],
            availability: 'full-time',
            salaryExpectation: 4500,
            bio: 'Experienced domestic worker with references in Addis Ababa.',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker profile saved')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _postJob(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(workersApiProvider).createJob(
            jobType: 'live-in maid',
            location: 'Bole, Addis Ababa',
            salaryOffer: 5000,
            requirements: 'References required',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.suffix,
    required this.icon,
  });

  final String label;
  final String value;
  final String? suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              children: [
                TextSpan(text: value),
                if (suffix != null)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
