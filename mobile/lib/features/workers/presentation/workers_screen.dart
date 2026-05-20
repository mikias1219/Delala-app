import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

final workersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(apiClientProvider).getWorkers();
});

class WorkersScreen extends ConsumerWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(workersProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e is ApiException ? e.message : 'Failed to load workers'),
        ),
        data: (workers) {
          if (workers.isEmpty) {
            return const Center(
              child: Text('No worker profiles yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final w = workers[index] as Map<String, dynamic>;
              final user = w['user'] as Map<String, dynamic>?;
              final skills = (w['skills'] as List<dynamic>?)?.join(', ') ?? '';
              return Card(
                child: ListTile(
                  title: Text(user?['fullName']?.toString() ?? 'Worker'),
                  subtitle: Text('$skills\nRating: ${w['ratingAvg']}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
