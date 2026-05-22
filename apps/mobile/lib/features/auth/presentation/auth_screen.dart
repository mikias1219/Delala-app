import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/otp_input_field.dart';
import '../../../core/widgets/phone_text_field.dart';
import '../../../core/widgets/role_selection_grid.dart';
import '../data/auth_api.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isRegister = false;
  bool _otpSent = false;
  bool _loading = false;
  bool _acceptedTerms = false;
  String _role = 'renter';
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() {
          _isRegister = _tabs.index == 1;
          _resetOtpStep();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _resetOtpStep() {
    _otpSent = false;
    _otpController.clear();
    _devCode = null;
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegister && !_acceptedTerms) {
      _snack('Please accept the terms to continue', isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _devCode = null;
    });

    try {
      final phone = Validators.normalizePhone(_phoneController.text);
      final result = await ref.read(authApiProvider).requestOtp(
            phone,
            role: _isRegister ? _role : null,
            isRegistration: _isRegister,
          );
      setState(() => _otpSent = true);
      _devCode = result['devCode'] as String?;
      _snack('Verification code sent');
    } on ApiException catch (e) {
      _snack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final phone = Validators.normalizePhone(_phoneController.text);
      await ref.read(currentUserProvider.notifier).verifyOtp(
            phone,
            _otpController.text.trim(),
            role: _isRegister ? _role : null,
          );
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      _snack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(isRegister: _isRegister),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Sign in'),
                Tab(text: 'Create account'),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isRegister && !_otpSent) ...[
                        Text(
                          'Choose account type',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        RoleSelectionGrid(
                          selectedRole: _role,
                          enabled: !_otpSent,
                          onSelected: (r) => setState(() => _role = r),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_otpSent)
                        const _StepBadge(step: 2, label: 'Verify your number')
                      else
                        _StepBadge(
                          step: 1,
                          label: _isRegister ? 'Your mobile number' : 'Welcome back',
                        ),
                      const SizedBox(height: 16),
                      PhoneTextField(
                        controller: _phoneController,
                        enabled: !_otpSent,
                        validator: Validators.phone,
                        onSubmitted: _otpSent ? null : _requestOtp,
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        OtpInputField(
                          controller: _otpController,
                          onCompleted: _loading ? null : _verifyOtp,
                        ),
                        if (_devCode != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.developer_mode, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dev code: $_devCode',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(_resetOtpStep),
                          child: const Text('Change phone number'),
                        ),
                      ],
                      if (_isRegister && !_otpSent) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: _acceptedTerms,
                          onChanged: (v) =>
                              setState(() => _acceptedTerms = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'I agree to Delala Terms & Privacy Policy',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading
                            ? null
                            : (_otpSent ? _verifyOtp : _requestOtp),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_otpSent
                                ? 'Verify & continue'
                                : 'Send verification code'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delala',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isRegister
                ? 'Create your verified account'
                : 'Trusted homes & domestic work in Addis Ababa',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step, required this.label});

  final int step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            '$step',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
