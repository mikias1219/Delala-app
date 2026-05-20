// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trusted Home Connect';

  @override
  String get loginTitle => 'Sign in with your phone';

  @override
  String get phoneHint => '09XXXXXXXX';

  @override
  String get requestOtp => 'Send code';

  @override
  String get verifyOtp => 'Verify';

  @override
  String get otpHint => '6-digit code';

  @override
  String get properties => 'Properties';

  @override
  String get workers => 'Workers';

  @override
  String get profile => 'Profile';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'አማርኛ';
}
