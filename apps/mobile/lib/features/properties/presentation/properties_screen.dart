import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/property_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/properties_api.dart';

final propertiesProvider = FutureProvider.autoDispose<List<PropertyModel>>((ref) {
  return ref.watch(propertiesApiProvider).search();
});

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(propertiesProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isOwner = user?.role == 'owner';

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(propertiesProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.wifi_off_outlined,
          title: 'Could not load homes',
          message: e is ApiException ? e.message : 'Check your connection',
          action: FilledButton(
            onPressed: () => ref.invalidate(propertiesProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                EmptyState(
                  icon: Icons.home_outlined,
                  title: isOwner ? 'No listings yet' : 'No homes available',
                  message: isOwner
                      ? 'Verified listings appear here after admin approval.'
                      : 'Check back soon for verified rentals in Addis Ababa.',
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length + (isOwner ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (isOwner && index == 0) {
                return _OwnerBanner();
              }
              final item = items[isOwner ? index - 1 : index];
              return _PropertyCard(
                property: item,
                onTap: () => context.push('/properties/${item.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New listings need admin verification before renters can see them.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property, required this.onTap});

  final PropertyModel property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: AppColors.seed.withValues(alpha: 0.08),
              child: Icon(
                Icons.apartment,
                size: 48,
                color: AppColors.seed.withValues(alpha: 0.4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _StatusChip(status: property.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ETB ${property.priceEtb} / month',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property.bedrooms} bed · Verified listing',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final verified = status == 'verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verified
            ? AppColors.success.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        verified ? 'Verified' : status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: verified ? AppColors.success : Colors.orange.shade800,
        ),
      ),
    );
  }
}
