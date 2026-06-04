import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/application_model.dart';
import '../../data/models/booth_package_model.dart';
import '../../data/models/booth_spot_model.dart';
import '../../data/models/exhibition_model.dart';
import '../../data/models/user_model.dart';

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

import '../../providers/auth_provider.dart';
import 'app_routes.dart';

class AppRouter {
  // Keep the last selected exhibition for fallback navigation.
  static ExhibitionModel? _lastExhibition;

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      // Start the app from the public/exhibitor home route.
      initialLocation: AppRoutes.root,

      // Refresh redirect logic when auth state changes.
      refreshListenable: authProvider,

      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isInitialized = authProvider.isInitialized;
        final user = authProvider.currentUser;

        // Check if current route is login or register.
        final isAuthRoute = state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register;

        // Wait until auth checking is completed.
        if (!isInitialized) return null;

        // Block protected routes when user is not logged in.
        if (!isLoggedIn) {
          if (state.matchedLocation.startsWith('/admin') ||
              state.matchedLocation.startsWith('/organizer')) {
            return AppRoutes.root;
          }

          // Allow guest users to stay on public routes.
          return null;
        }

        // Get current user role after login.
        final role = user?.role;

        if (role == 'Admin') {
          // Send admin to admin dashboard.
          if (state.matchedLocation == AppRoutes.root || isAuthRoute) {
            return AppRoutes.admin;
          }

          // Prevent admin from opening organizer routes.
          if (state.matchedLocation.startsWith('/organizer')) {
            return AppRoutes.admin;
          }
        } else if (role == 'Organizer') {
          // Send organizer to organizer dashboard.
          if (state.matchedLocation == AppRoutes.root || isAuthRoute) {
            return AppRoutes.organizer;
          }

          // Prevent organizer from opening admin routes.
          if (state.matchedLocation.startsWith('/admin')) {
            return AppRoutes.organizer;
          }
        } else if (role == 'Exhibitor') {
          // Prevent exhibitor from returning to auth screen.
          if (isAuthRoute) {
            return AppRoutes.root;
          }

          // Prevent exhibitor from opening admin or organizer routes.
          if (state.matchedLocation.startsWith('/admin') ||
              state.matchedLocation.startsWith('/organizer')) {
            return AppRoutes.root;
          }
        }

        // No redirect needed.
        return null;
      },

      routes: [
        // Public/exhibitor home route.
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => const ExhibitorWrapper(),
        ),

        // Login route.
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) =>
              const AuthScreen(initialMode: AuthMode.login),
        ),

        // Register route.
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) =>
              const AuthScreen(initialMode: AuthMode.register),
        ),

        // Organizer dashboard route.
        GoRoute(
          path: AppRoutes.organizer,
          builder: (context, state) => const OrganizerWrapper(),
        ),

        // Organizer create exhibition route.
        GoRoute(
          path: AppRoutes.organizerCreateExhibition,
          builder: (context, state) => const CreateExhibitionScreen(),
        ),

        // Organizer booth package management route.
        GoRoute(
          path: AppRoutes.organizerBoothPackages,
          builder: (context, state) {
            // Get exhibition data from navigation extra.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show fallback screen if exhibition data is missing.
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }

            // Save exhibition for related route fallback.
            _lastExhibition = exhibition;

            return BoothPackagesScreen(exhibition: exhibition);
          },
        ),

        // Organizer booth spot management route.
        GoRoute(
          path: AppRoutes.organizerBoothSpots,
          builder: (context, state) {
            // Get exhibition data from navigation extra.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show fallback screen if exhibition data is missing.
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }

            // Save exhibition for related route fallback.
            _lastExhibition = exhibition;

            return BoothSpotsScreen(exhibition: exhibition);
          },
        ),

        // Organizer exhibition details route.
        GoRoute(
          path: AppRoutes.organizerExhibitionDetails,
          builder: (context, state) {
            // Get exhibition data from navigation extra.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show error screen if exhibition data is missing.
            if (exhibition == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Exhibition data missing')),
              );
            }

            // Save exhibition for related route fallback.
            _lastExhibition = exhibition;

            return OrganizerExhibitionDetailsScreen(exhibition: exhibition);
          },
        ),

        // Public exhibition details route.
        GoRoute(
          path: AppRoutes.exhibitionDetails,
          builder: (context, state) {
            // Get selected exhibition from previous screen.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show fallback screen if exhibition data is missing.
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }

            // Save exhibition for next related screen.
            _lastExhibition = exhibition;

            return ExhibitionDetailsScreen(exhibition: exhibition);
          },
        ),

        // Booth selection route.
        GoRoute(
          path: AppRoutes.selectBooth,
          builder: (context, state) {
            // Get selected exhibition from previous screen.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show fallback screen if exhibition data is missing.
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }

            // Save exhibition for next related screen.
            _lastExhibition = exhibition;

            return SelectBoothScreen(exhibition: exhibition);
          },
        ),

        // Guided booth application flow route.
        GoRoute(
          path: AppRoutes.boothApplicationFlow,
          builder: (context, state) {
            // Get selected exhibition from previous screen.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show fallback screen if exhibition data is missing.
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }

            // Save exhibition for next related screen.
            _lastExhibition = exhibition;

            return BoothApplicationFlowScreen(exhibition: exhibition);
          },
        ),

        // Application form route.
        GoRoute(
          path: AppRoutes.applicationForm,
          builder: (context, state) {
            // Get form data from previous selection flow.
            final data = state.extra as Map<String, dynamic>?;

            // Check required data before opening the form.
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
              boothPackage: data['boothPackage'] as BoothPackageModel,
            );
          },
        ),

        // Shared application details route.
        GoRoute(
          path: AppRoutes.applicationDetails,
          builder: (context, state) {
            // Get selected application from previous screen.
            final application = state.extra as ApplicationModel?;

            // Show error screen if application data is missing.
            if (application == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Application data missing')),
              );
            }

            return ApplicationDetailsScreen(application: application);
          },
        ),

        // Notification route.
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),

        // Admin dashboard route.
        GoRoute(
          path: AppRoutes.admin,
          builder: (context, state) => const AdminWrapper(),
        ),

        // Admin user details route.
        GoRoute(
          path: AppRoutes.adminUserDetails,
          builder: (context, state) {
            // Get selected user from admin user list.
            final user = state.extra as UserModel?;

            // Show error screen if user data is missing.
            if (user == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('User data missing')),
              );
            }

            return AdminUserDetailsScreen(user: user);
          },
        ),

        // Admin create exhibition route.
        GoRoute(
          path: AppRoutes.adminCreateExhibition,
          builder: (context, state) => const CreateExhibitionScreen(),
        ),

        // Admin exhibition details route.
        GoRoute(
          path: AppRoutes.adminExhibitionDetails,
          builder: (context, state) {
            // Get exhibition data from navigation extra.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show error screen if exhibition data is missing.
            if (exhibition == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Exhibition data missing')),
              );
            }

            // Save exhibition for related route fallback.
            _lastExhibition = exhibition;

            return OrganizerExhibitionDetailsScreen(exhibition: exhibition);
          },
        ),

        // Admin booth package management route.
        GoRoute(
          path: AppRoutes.adminBoothPackages,
          builder: (context, state) {
            // Get exhibition data from navigation extra.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show fallback screen if exhibition data is missing.
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }

            // Save exhibition for related route fallback.
            _lastExhibition = exhibition;

            return BoothPackagesScreen(exhibition: exhibition);
          },
        ),

        // Admin booth spot management route.
        GoRoute(
          path: AppRoutes.adminBoothSpots,
          builder: (context, state) {
            // Get exhibition data from navigation extra.
            final exhibition = state.extra as ExhibitionModel? ?? _lastExhibition;

            // Show fallback screen if exhibition data is missing.
            if (exhibition == null) {
              return const Scaffold(
                body: Center(child: Text('Exhibition not found')),
              );
            }

            // Save exhibition for related route fallback.
            _lastExhibition = exhibition;

            return BoothSpotsScreen(exhibition: exhibition);
          },
        ),

        // Personal information route.
        GoRoute(
          path: AppRoutes.personalInformation,
          builder: (context, state) => const PersonalInformationScreen(),
        ),
      ],
    );
  }
}