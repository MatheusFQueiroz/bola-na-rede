import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bolanarede_web/features/auth/presentation/views/login_page.dart';
import 'package:bolanarede_web/features/auth/presentation/views/register_page.dart';
import 'package:bolanarede_web/features/campos/presentation/views/courts_page.dart';
import 'package:bolanarede_web/features/campos/presentation/views/field_form_page.dart';
import 'package:bolanarede_web/features/campos/presentation/views/field_detail_page.dart';
import 'package:bolanarede_web/features/campos/presentation/views/fields_list_page.dart';
import 'package:bolanarede_web/features/clientes/presentation/views/customer_detail_page.dart';
import 'package:bolanarede_web/features/clientes/presentation/views/customers_page.dart';
import 'package:bolanarede_web/features/configuracoes/presentation/views/settings_page.dart';
import 'package:bolanarede_web/features/dashboard/presentation/views/dashboard_page.dart';
import 'package:bolanarede_web/features/disponibilidade/presentation/views/availability_page.dart';
import 'package:bolanarede_web/features/planos/presentation/views/recurring_plan_detail_page.dart';
import 'package:bolanarede_web/features/planos/presentation/views/recurring_plan_form_page.dart';
import 'package:bolanarede_web/features/planos/presentation/views/recurring_plans_page.dart';
import 'package:bolanarede_web/features/precos/presentation/views/pricing_page.dart';
import 'package:bolanarede_web/features/relatorios/presentation/views/reports_page.dart';
import 'package:bolanarede_web/features/reservas/presentation/views/reservation_detail_page.dart';
import 'package:bolanarede_web/features/reservas/presentation/views/reservation_form_page.dart';
import 'package:bolanarede_web/features/reservas/presentation/views/reservations_list_page.dart';
import 'package:bolanarede_web/shared/widgets/web_shell.dart';

abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const fields = '/dashboard/fields';
  static const fieldNew = '/dashboard/fields/new';
  static const fieldDetail = '/dashboard/fields/:fieldId';
  static const fieldEdit = '/dashboard/fields/:fieldId/edit';
  static const courts = '/dashboard/fields/:fieldId/courts';
  static const pricing = '/dashboard/fields/:fieldId/pricing';
  static const availability = '/dashboard/fields/:fieldId/availability';
  static const reservations = '/dashboard/reservations';
  static const reservationNew = '/dashboard/reservations/new';
  static const reservationDetail = '/dashboard/reservations/:reservationId';
  static const recurringPlans = '/dashboard/recurring-plans';
  static const recurringPlanNew = '/dashboard/recurring-plans/new';
  static const recurringPlanDetail = '/dashboard/recurring-plans/:planId';
  static const customers = '/dashboard/customers';
  static const customerDetail = '/dashboard/customers/:customerId';
  static const reports = '/dashboard/reports';
  static const settings = '/dashboard/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final title = _getTitleForPath(state.matchedLocation);
          return WebShell(topbarTitle: title, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.fields,
            builder: (_, __) => const FieldsListPage(), 
          ),
          GoRoute(
            path: AppRoutes.fieldNew,
            builder: (_, __) => const FieldFormPage(),
          ),
          GoRoute(
            path: '/dashboard/fields/:fieldId',
            builder: (context, state) => FieldDetailPage(
              fieldId: state.pathParameters['fieldId']!,
            ),
          ),
          GoRoute(
            path: '/dashboard/fields/:fieldId/edit',
            builder: (context, state) => FieldFormPage(
              fieldId: state.pathParameters['fieldId'],
            ),
          ),
          GoRoute(
            path: '/dashboard/fields/:fieldId/courts',
            builder: (context, state) => CourtsPage(
              fieldId: state.pathParameters['fieldId']!,
            ),
          ),
          GoRoute(
            path: '/dashboard/fields/:fieldId/pricing',
            builder: (context, state) => PricingPage(
              fieldId: state.pathParameters['fieldId']!,
            ),
          ),
          GoRoute(
            path: '/dashboard/fields/:fieldId/availability',
            builder: (context, state) => AvailabilityPage(
              fieldId: state.pathParameters['fieldId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.reservations,
            builder: (_, __) => const ReservationsListPage(),
          ),
          GoRoute(
            path: AppRoutes.reservationNew,
            builder: (_, __) => const ReservationFormPage(),
          ),
          GoRoute(
            path: '/dashboard/reservations/:reservationId',
            builder: (context, state) => ReservationDetailPage(
              reservationId: state.pathParameters['reservationId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.recurringPlans,
            builder: (_, __) => const RecurringPlansPage(),
          ),
          GoRoute(
            path: AppRoutes.recurringPlanNew,
            builder: (_, __) => const RecurringPlanFormPage(),
          ),
          GoRoute(
            path: '/dashboard/recurring-plans/:planId',
            builder: (context, state) => RecurringPlanDetailPage(
              planId: state.pathParameters['planId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (_, __) => const CustomersPage(),
          ),
          GoRoute(
            path: '/dashboard/customers/:customerId',
            builder: (context, state) => CustomerDetailPage(
              customerId: state.pathParameters['customerId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, __) => const ReportsPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});

String _getTitleForPath(String path) {
  if (path == AppRoutes.dashboard) return 'Visão Geral';
  if (path == AppRoutes.fields) return 'Meus Campos';
  if (path.contains('/fields/new')) return 'Cadastrar Campo';
  if (path.contains('/courts')) return 'Quadras';
  if (path.contains('/pricing')) return 'Regras de Preço';
  if (path.contains('/availability')) return 'Disponibilidade';
  if (path == AppRoutes.reservations) return 'Reservas';
  if (path.contains('/reservations/new')) return 'Nova Reserva';
  if (path == AppRoutes.recurringPlans) return 'Planos Recorrentes';
  if (path.contains('/recurring-plans/new')) return 'Novo Plano';
  if (path == AppRoutes.customers) return 'Clientes';
  if (path == AppRoutes.reports) return 'Relatórios';
  if (path == AppRoutes.settings) return 'Configurações';
  return 'BolaNaRede';
}
