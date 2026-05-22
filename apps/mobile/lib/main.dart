import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/auth/auth_session.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TokenStorage.init();

  final container = ProviderContainer();
  await container.read(authSessionProvider).bootstrap();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () => runApp(
      UncontrolledProviderScope(
        container: container,
        child: const DelalaApp(),
      ),
    ),
    (error, stack) {
      debugPrint('Delala error: $error\n$stack');
    },
  );
}
