import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// Must be a top-level function annotated with @pragma so the Dart VM keeps it
// alive in a separate isolate when the app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised when this runs (flutter_fire handles it).
  firebaseMessagingBackgroundHandler(message);
}

Future<void> main() async {
  // Ensure bindings are initialized before any plugin calls.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // Register the background handler BEFORE calling runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialise FCM permissions, local notification channel, and tap handlers.
  await NotificationService.instance.initialize();

  // Try to set Crashlytics collection state. Wrap in try/catch because
  // plugin native-side registration may not be ready in some edge cases.
  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  } catch (e) {
    debugPrint('Warning: Crashlytics collection toggle failed: $e');
  }

  // Redirect Flutter framework errors to Crashlytics (safe-guarded).
  FlutterError.onError = (FlutterErrorDetails details) {
    // Always present error to the console.
    FlutterError.presentError(details);
    if (!kDebugMode) {
      try {
        // Prefer recordFlutterError which is non-fatal for framework errors.
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } catch (e) {
        debugPrint('Crashlytics.recordFlutterError failed: $e');
      }
    }
  };

  // Catch errors that escape the Flutter framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (e) {
        debugPrint('Crashlytics.recordError failed in PlatformDispatcher: $e');
      }
    }
    // Return false so the error is still reported to the console by the
    // platform. We don't want to swallow fatal system errors.
    return false;
  };

  // Run the app in a guarded zone so uncaught async errors are reported.
  runZonedGuarded<Future<void>>(
    () async {
      runApp(const ProviderScope(child: XplooriaApp()));
    },
    (error, stack) async {
      if (!kDebugMode) {
        try {
          await FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            fatal: true,
          );
        } catch (e) {
          debugPrint('Crashlytics.recordError failed in zone handler: $e');
        }
      } else {
        debugPrint('Uncaught async error: $error');
        debugPrintStack(stackTrace: stack);
      }
    },
  );
}

class XplooriaApp extends ConsumerWidget {
  const XplooriaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'Xplooria',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
