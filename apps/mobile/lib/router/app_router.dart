import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_session.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/properties/presentation/property_detail_screen.dart';
import '../features/shell/presentation/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (!session.ready) {
        return loc == '/splash' ? null : '/splash';
      }

      if (loc == '/splash') {
        return session.loggedIn ? '/home' : '/login';
      }

      final onAuth = loc == '/login';
      if (!session.loggedIn && !onAuth) return '/login';
      if (session.loggedIn && onAuth) return '/home';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\n${state.error}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) => PropertyDetailScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 56, color: Color(0xFF1B7A5C)),
            SizedBox(height: 16),
            Text(
              'Delala',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
