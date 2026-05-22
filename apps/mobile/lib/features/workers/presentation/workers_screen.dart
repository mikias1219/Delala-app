import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/workers_api.dart';

final workersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(workersApiProvider).list();
});

class WorkersScreen extends ConsumerWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workersProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isWorker = user?.role == 'worker';

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(workersProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.wifi_off_outlined,
          title: 'Could not load workers',
          message: e is ApiException ? e.message : 'Try again',
          action: FilledButton(
            onPressed: () => ref.invalidate(workersProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (workers) {
          if (workers.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                EmptyState(
                  icon: Icons.people_outline,
                  title: isWorker ? 'Complete your profile' : 'No workers yet',
                  message: isWorker
                      ? 'Add skills and availability from your Account tab.'
                      : 'Workers with verified profiles will appear here.',
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: workers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final w = workers[index] as Map<String, dynamic>;
              return _WorkerCard(data: w);
            },
          );
        },
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final user = data['user'] as Map<String, dynamic>?;
    final skills = (data['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final rating = data['ratingAvg']?.toString() ?? '—';
    final availability = data['availability']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.seed.withValues(alpha: 0.12),
              child: const Icon(Icons.person, color: AppColors.seed),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?['fullName']?.toString() ?? 'Domestic worker',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  if (availability.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      availability,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skills.take(4).map((s) {
                      return Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(rating, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
