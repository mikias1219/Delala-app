class Validators {
  static final _ethiopianPhone = RegExp(r'^09\d{8}$');

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your phone number';
    }
    final digits = value.replaceAll(RegExp(r'\s+'), '');
    if (!_ethiopianPhone.hasMatch(digits)) {
      return 'Use format 09XX XXX XXXX (10 digits)';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the 6-digit code';
    }
    if (value.trim().length != 6 || int.tryParse(value.trim()) == null) {
      return 'Code must be 6 digits';
    }
    return null;
  }

  static String normalizePhone(String input) {
    return input.replaceAll(RegExp(r'\s+'), '');
  }
}
