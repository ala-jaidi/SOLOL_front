import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/screens/home_page.dart';
import 'package:lidarmesure/screens/patients_page.dart';
import 'package:lidarmesure/screens/patient_detail_page.dart';
import 'package:lidarmesure/screens/scan_page.dart';
import 'package:lidarmesure/screens/scan_result_page.dart';
import 'package:lidarmesure/screens/history_page.dart';
import 'package:lidarmesure/screens/chat_page.dart';
import 'package:lidarmesure/screens/notifications_page.dart';
import 'package:lidarmesure/screens/podiatrist_profile_page.dart';
import 'package:lidarmesure/screens/help_page.dart';
import 'package:lidarmesure/screens/login_page.dart';
import 'package:lidarmesure/screens/signup_page.dart';
import 'package:lidarmesure/screens/add_patient_page.dart';
import 'package:lidarmesure/screens/add_session_page.dart';
import 'package:lidarmesure/screens/session_detail_page.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isAuthenticated = SupabaseConfig.auth.currentUser != null;
      final isOnLoginPage = state.matchedLocation == AppRoutes.login;
      final isOnSignupPage = state.matchedLocation == AppRoutes.signup;
      // Handle root path
      if (state.matchedLocation == '/' || state.uri.path == '/') {
        return isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      if (!isAuthenticated && !isOnLoginPage && !isOnSignupPage) {
        return AppRoutes.login;
      }
      if (isAuthenticated && (isOnLoginPage || isOnSignupPage)) {
        return AppRoutes.home;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Page introuvable'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go(AppRoutes.home), child: const Text("Aller à l'accueil")),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        redirect: (context, state) => SupabaseConfig.auth.currentUser != null ? AppRoutes.home : AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const SignupPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.patients,
        name: 'patients',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const PatientsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.addPatient,
        name: 'addPatient',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const AddPatientPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.addSession,
        name: 'addSession',
        pageBuilder: (context, state) {
          final preId = state.uri.queryParameters['patientId'];
          return NoTransitionPage(child: AddSessionPage(preselectedPatientId: preId));
        },
      ),
      GoRoute(
        path: '/patient/:id',
        name: 'patientDetail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoTransitionPage(
            child: PatientDetailPage(patientId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scan,
        name: 'scan',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const ScanPage(),
        ),
      ),
      GoRoute(
        path: '/session/:id',
        name: 'sessionDetail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoTransitionPage(
            child: SessionDetailPage(sessionId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scanResult,
        name: 'scanResult',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NoTransitionPage(
            child: ScanResultPage(scanData: extra),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const HistoryPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const ChatPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const PodiatristProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const HelpPage(),
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String patients = '/patients';
  static const String addPatient = '/add-patient';
  static const String addSession = '/add-session';
  static const String scan = '/scan';
  static const String scanResult = '/scan-result';
  static const String history = '/history';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String help = '/help';
  static const String sessionDetail = '/session/:id';
}
