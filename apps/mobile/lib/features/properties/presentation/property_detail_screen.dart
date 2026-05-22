import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/property_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';

final propertyDetailProvider =
    FutureProvider.autoDispose.family<PropertyModel, String>((ref, id) {
  return ref.watch(apiClientProvider).getProperty(id);
});

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  bool _booking = false;

  Future<void> _requestViewing() async {
    setState(() => _booking = true);
    try {
      await ref.read(apiClientProvider).requestViewing(
            propertyId: widget.propertyId,
            notes: 'Requested via THCP app',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing request sent to owner')),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(propertyDetailProvider(widget.propertyId));
    final user = ref.watch(currentUserProvider).valueOrNull;
    final canBook = user?.role == 'renter';

    return Scaffold(
      appBar: AppBar(title: const Text('Property')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (property) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              property.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ETB ${property.priceEtb} / month · ${property.bedrooms} bedrooms',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(property.description),
            const SizedBox(height: 32),
            if (canBook)
              FilledButton(
                onPressed: _booking ? null : _requestViewing,
                child: _booking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request viewing'),
              )
            else
              Text(
                'Sign in as a renter to request a viewing.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
