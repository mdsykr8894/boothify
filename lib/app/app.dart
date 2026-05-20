import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../providers/application_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booth_provider.dart';
import '../providers/booth_spot_provider.dart';
import '../providers/exhibition_provider.dart';
import '../providers/user_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class BoothifyApp extends StatefulWidget {
  const BoothifyApp({super.key});

  @override
  State<BoothifyApp> createState() => _BoothifyAppState();
}

class _BoothifyAppState extends State<BoothifyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider()..loadCurrentUser();
    _router = AppRouter.createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => ExhibitionProvider()),
        ChangeNotifierProvider(create: (_) => BoothProvider()),
        ChangeNotifierProvider(create: (_) => BoothSpotProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Remove native splash screen once auth state is initialized
          if (auth.isInitialized) {
            FlutterNativeSplash.remove();
          }

          return MaterialApp.router(
            title: 'Boothify',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              overscroll: false,
            ),
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                  systemNavigationBarColor: AppColors.background,
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}


