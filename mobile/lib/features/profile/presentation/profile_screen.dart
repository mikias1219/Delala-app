import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }
          final score = user.trustScore?['score'] ?? '—';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ListTile(
                title: Text(user.fullName ?? 'No name'),
                subtitle: Text('${user.phone} · ${user.role}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.verified_user),
                title: const Text('Trust score'),
                trailing: Text('$score / 100', style: Theme.of(context).textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Account status'),
                trailing: Text(user.status),
              ),
              if (user.role == 'worker') ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _setupWorkerProfile(context, ref),
                  child: const Text('Set up worker profile'),
                ),
              ],
              if (user.role == 'employer') ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _postJob(context, ref),
                  child: const Text('Post a job'),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(currentUserProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _setupWorkerProfile(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(apiClientProvider).upsertWorkerProfile(
            skills: ['cleaning', 'cooking'],
            availability: 'full-time',
            salaryExpectation: 4500,
            bio: 'Experienced domestic worker in Addis Ababa.',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker profile saved')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _postJob(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(apiClientProvider).createJob(
            jobType: 'live-in maid',
            location: 'Bole, Addis Ababa',
            salaryOffer: 5000,
            requirements: 'References required',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
