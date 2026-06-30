import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/onboarding_provider.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/notifications/presentation/providers/fcm_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  initialOnboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(const ProviderScope(child: GeereelApp()));
}

/// Must be a top-level function so the platform can invoke it in a
/// separate isolate when a push arrives while the app isn't in the
/// foreground. Currently a no-op: the OS shows the notification from the
/// payload itself; this hook exists for future data-only message handling
/// (e.g. updating a local badge count) once a Cloud Function sends those.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class GeereelApp extends ConsumerWidget {
  const GeereelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    ref.listen(authStateProvider, (previous, next) {
      final uid = next.value;
      if (uid != null) {
        ref.read(fcmTokenManagerProvider).registerToken(uid);
      }
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
