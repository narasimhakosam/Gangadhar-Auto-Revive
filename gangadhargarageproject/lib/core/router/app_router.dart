
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/login_screen.dart';
import '../../features/dashboards/dashboard_screen.dart';
import '../../features/vehicles/vehicle_search_screen.dart';
import '../../features/vehicles/vehicle_detail_screen.dart';
import '../../features/billing/new_bill_screen.dart';
import '../../features/billing/pdf_preview_screen.dart';
import '../../features/images/image_upload_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/manage_workers_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      // Use Supabase session instead of SharedPreferences token
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isLoggingIn = state.matchedLocation == '/login';
      
      // Let splash and onboarding flow normally
      if (isSplash || isOnboarding) {
        return null;
      }

      // Standard auth redirect for protected routes
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      // If logged in but trying to access login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }
      
      return null;
    },

    routes: [

      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehicleSearchScreen(),
      ),
      GoRoute(
        path: '/vehicles/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/bills/new',
        builder: (context, state) => const NewBillScreen(),
      ),
      GoRoute(
        path: '/bills/view/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PdfPreviewScreen(billId: id);
        },
      ),
      GoRoute(
        path: '/bills/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NewBillScreen(billId: id);
        },
      ),
      GoRoute(
        path: '/images/upload/:vehicleId',
        builder: (context, state) {
          final vehicleId = state.pathParameters['vehicleId']!;
          final visitId = state.uri.queryParameters['visitId'];
          return ImageUploadScreen(vehicleId: vehicleId, visitId: visitId);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/workers',
        builder: (context, state) => const ManageWorkersScreen(),
      ),
    ],
  );
}
