import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

class AgroNetApp extends ConsumerWidget {
  const AgroNetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'AgroNet AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      routerDelegate: goRouter.routerDelegate,
      routeInformationParser: goRouter.routeInformationParser,
      routeInformationProvider: goRouter.routeInformationProvider,
      backButtonDispatcher: AppBackButtonDispatcher(),
    );
  }
}

class AppBackButtonDispatcher extends RootBackButtonDispatcher {
  @override
  Future<bool> didPopRoute() async {
    final location = goRouter.routerDelegate.currentConfiguration.uri.toString();
    if (location != '/dashboard' && !location.startsWith('/splash') && !location.startsWith('/login')) {
      goRouter.go('/dashboard');
      return true;
    }
    return super.didPopRoute();
  }
}
