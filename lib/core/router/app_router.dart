import 'package:go_router/go_router.dart';

// OJO con los paths: estamos dentro de lib/core/router/
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/account_page.dart';
import '../../features/notifications/presentation/pages/reminders_page.dart';
import '../../features/profile/presentation/pages/privacy_security_page.dart';
import '../../features/cattle/presentation/pages/cattle_list_page.dart';
import '../../features/assistant/presentation/pages/assistant_chat_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/cattle/presentation/pages/cattle_detail_page.dart';
import '../../features/cattle/presentation/pages/cattle_zeal_page.dart';
import '../../features/cattle/presentation/pages/cattle_vaccine_page.dart'; // ✅ IMPORT AGREGADO

final appRouter = GoRouter(
  initialLocation: '/welcome',

  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const RemindersPage(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacySecurityPage(),
    ),
    GoRoute(
      path: '/cattle',
      builder: (context, state) => const CattleListPage(),
    ),
    GoRoute(
      path: '/assistant',
      builder: (context, state) => const AssistantChatPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    // ✅ RUTA MODIFICADA: Ahora acepta datos extra
    GoRoute(
      path: '/cattle/:id',
      name: 'cattle-detail',
      builder: (context, state) {
        final cattleId = state.pathParameters['id']!;
        // ✅ CORRECCIÓN: Casteo correcto
        final cattleData = (state.extra as Map<String, dynamic>?) ?? {};
        return CattleDetailPage(
          cattleId: cattleId,
          cattleData: cattleData,
        );
      },
    ),

    GoRoute(
      path: '/cattle/:id/zeal',
      name: 'cattle-zeal',
      builder: (context, state) {
        final cattleId = state.pathParameters['id']!;
        return CattleZealPage(cattleId: cattleId);
      },
    ),

    GoRoute(
      path: '/cattle/:id/vaccine',
      name: 'cattle-vaccine',
      builder: (context, state) {
        final cattleId = state.pathParameters['id']!;
        return CattleVaccinePage(cattleId: cattleId);
      },
    ), // ✅ SOLO UNA COMA Y UN PARÉNTESIS AQUÍ
  ],
);