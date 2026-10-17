import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/vehicles/screens/vehicles_screen.dart';
import '../../features/maintenance/screens/maintenance_screen.dart';
import '../../features/fleet/screens/fleet_screen.dart';
import '../../core/widgets/main_scaffold.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLogin = state.matchedLocation == '/login';
      if (session == null && !isLogin) return '/login';
      if (session != null && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/vehicles', builder: (context, state) => const VehiclesScreen()),
          GoRoute(path: '/maintenance', builder: (context, state) => const MaintenanceScreen()),
          GoRoute(path: '/fleet', builder: (context, state) => const FleetScreen()),
        ],
      ),
    ],
  );
}
