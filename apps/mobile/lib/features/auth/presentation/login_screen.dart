import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_api.dart';
import '../../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';

const _roles = [
  ('renter', 'Renter', 'Find a home'),
  ('owner', 'Owner', 'List property'),
  ('worker', 'Worker', 'Domestic jobs'),
  ('employer', 'Employer', 'Hire help'),
];

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _role = 'renter';
  bool _otpSent = false;
  bool _loading = false;
  String? _devCode;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _devCode = null;
    });
    try {
      final result = await ref.read(authApiProvider).requestOtp(
        _phoneController.text.trim(),
        role: _role,
      );
      setState(() {
        _otpSent = true;
        _devCode = result['devCode'] as String?;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent')),
        );
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    try {
      await ref.read(currentUserProvider.notifier).verifyOtp(
            _phoneController.text.trim(),
            _otpController.text.trim(),
            role: _role,
          );
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Text(
              'Delala',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verified rentals & domestic workers in Addis Ababa',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Text('I am a', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roles.map((r) {
                final selected = _role == r.$1;
                return ChoiceChip(
                  label: Text(r.$2),
                  selected: selected,
                  onSelected: _otpSent
                      ? null
                      : (_) => setState(() => _role = r.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              enabled: !_otpSent,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '09XXXXXXXX',
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  counterText: '',
                ),
              ),
              if (_devCode != null)
                Text(
                  'Dev OTP: $_devCode',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : (_otpSent ? _verifyOtp : _requestOtp),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_otpSent ? 'Verify & continue' : 'Send code'),
            ),
          ],
        ),
      ),
    );
  }
}
