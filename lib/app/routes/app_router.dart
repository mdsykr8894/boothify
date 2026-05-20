import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/application_model.dart';
import '../../data/models/booth_model.dart';
import '../../data/models/booth_spot_model.dart';
import '../../data/models/exhibition_model.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/exhibitor/explore/application_form_screen.dart';
import '../../features/exhibitor/explore/booth_application_flow_screen.dart';
import '../../features/exhibitor/explore/exhibition_details_screen.dart';
import '../../features/exhibitor/explore/select_booth_screen.dart';
import '../../features/organizer/exhibitions/booth_packages_screen.dart';
import '../../features/organizer/exhibitions/booth_spots_screen.dart';
import '../../features/organizer/exhibitions/create_exhibition_screen.dart';
import '../../features/organizer/exhibitions/organizer_exhibition_details_screen.dart';
import '../../features/shared/applications/application_details_screen.dart';
import '../../features/shared/notifications/notifications_screen.dart';
import '../../features/shared/profile/personal_information_screen.dart';
import '../../features/shared/wrappers/admin_wrapper.dart';
import '../../features/shared/wrappers/exhibitor_wrapper.dart';
import '../../features/shared/wrappers/organizer_wrapper.dart';
import '../../features/admin/users/admin_user_details_screen.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'app_routes.dart';

class AppRouter {
  static ExhibitionModel? _lastExhibition;

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.root,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isInitialized = authProvider.isInitialized;
        final user = authProvider.currentUser;
        
        final isAuthRoute = state.matchedLocation == AppRoutes.login || 
                           state.matchedLocation == AppRoutes.register;
        
        // Wait for auth to initialize before making major redirect decisions
        if (!isInitialized) return null;

        // 1. If not logged in, only allow public routes
        if (!isLoggedIn) {
          // If trying to access protected routes, send to login
          if (state.matchedLocation.startsWith('/admin') || 
              state.matchedLocation.startsWith('/organizer')) {
            return AppRoutes.root;
          }
          return null;
        }

        // 2. If logged in, handle role-based redirection
        final role = user?.role;

        if (role == 'Admin') {
          // Admin should be redirected to /admin if on root or auth routes
          if (state.matchedLocation == AppRoutes.root || isAuthRoute) {
            return AppRoutes.admin;
          }
          // Admin should not be in /organizer paths (they should use /admin instead)
          if (state.matchedLocation.startsWith('/organizer')) {
            return AppRoutes.admin;
          }
        } 
        
        else if (role == 'Organizer') {
          // Organizer should be redirected to /organizer if on root or auth routes
          if (state.matchedLocation == AppRoutes.root || isAuthRoute) {
            return AppRoutes.organizer;
          }
          // Organizer should not be in /admin paths
          if (state.matchedLocation.startsWith('/admin')) {
            return AppRoutes.organizer;
          }
        }

        else if (role == 'Exhibitor') {
          // Exhibitor should be redirected away from auth routes to root
          if (isAuthRoute) {
            return AppRoutes.root;
          }
          // Exhibitor should not be in /admin or /organizer paths
          if (state.matchedLocation.startsWith('/admin') || 
              state.matchedLocation.startsWith('/organizer')) {
            return AppRoutes.root;
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => const ExhibitorWrapper(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const AuthScreen(initialMode: AuthMode.login),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const AuthScreen(initialMode: AuthMode.register),
        ),
        GoRoute(
          path: AppRoutes.organizer,
          builder: (context, state) => const OrganizerWrapper(),
        ),
        GoRoute(
          path: AppRoutes.organizerCreateExhibition,
          builder: (context, state) => const CreateExhibitionScreen(),
        ),
        GoRoute(
          path: AppRoutes.organizerBoothPackages,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }
            _lastExhibition = exhibition;
            return BoothPackagesScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.organizerBoothSpots,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }
            _lastExhibition = exhibition;
            return BoothSpotsScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.organizerExhibitionDetails,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Exhibition data missing')),
              );
            }
            _lastExhibition = exhibition;
            return OrganizerExhibitionDetailsScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.exhibitionDetails,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }
            _lastExhibition = exhibition;
            return ExhibitionDetailsScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.selectBooth,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }
            _lastExhibition = exhibition;
            return SelectBoothScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.boothApplicationFlow,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }
            _lastExhibition = exhibition;
            return BoothApplicationFlowScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.applicationForm,
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>?;
            if (data == null || 
                data['exhibition'] == null || 
                data['boothSpot'] == null || 
                data['boothPackage'] == null) {
              return const Scaffold(
                body: Center(child: Text('Required data missing')),
              );
            }
            return ApplicationFormScreen(
              exhibition: data['exhibition'] as ExhibitionModel,
              boothSpot: data['boothSpot'] as BoothSpotModel,
              boothPackage: data['boothPackage'] as BoothModel,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.applicationDetails,
          builder: (context, state) {
            final application = state.extra as ApplicationModel?;
            if (application == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Application data missing')),
              );
            }
            return ApplicationDetailsScreen(application: application);
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.admin,
          builder: (context, state) => const AdminWrapper(),
        ),
        GoRoute(
          path: AppRoutes.adminUserDetails,
          builder: (context, state) {
            final user = state.extra as UserModel?;
            if (user == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('User data missing')),
              );
            }
            return AdminUserDetailsScreen(user: user);
          },
        ),
        GoRoute(
          path: AppRoutes.adminCreateExhibition,
          builder: (context, state) => const CreateExhibitionScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminExhibitionDetails,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Exhibition data missing')),
              );
            }
            _lastExhibition = exhibition;
            return OrganizerExhibitionDetailsScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.adminBoothPackages,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }
            _lastExhibition = exhibition;
            return BoothPackagesScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.adminBoothSpots,
          builder: (context, state) {
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }
            _lastExhibition = exhibition;
            return BoothSpotsScreen(exhibition: exhibition);
          },
        ),
        GoRoute(
          path: AppRoutes.personalInformation,
          builder: (context, state) => const PersonalInformationScreen(),
        ),
      ],
    );
  }
}
