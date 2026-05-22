import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneTextField extends StatelessWidget {
  const PhoneTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: validator,
      decoration: const InputDecoration(
        labelText: 'Mobile number',
        hintText: '09XX XXX XXXX',
        prefixIcon: Icon(Icons.phone_android_outlined),
        prefixText: '+251 ',
      ),
    );
  }
}
