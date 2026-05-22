import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputField extends StatelessWidget {
  const OtpInputField({
    super.key,
    required this.controller,
    this.onCompleted,
  });

  final TextEditingController controller;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            letterSpacing: 12,
            fontWeight: FontWeight.bold,
          ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: (v) {
        if (v.length == 6) onCompleted?.call();
      },
      decoration: const InputDecoration(
        labelText: 'Verification code',
        hintText: '• • • • • •',
        counterText: '',
      ),
    );
  }
}
