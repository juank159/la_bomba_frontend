import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pedidos_frontend/app/core/controllers/theme_controller.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// App configuration
import 'app/config/app_config.dart';
import 'app/config/routes.dart';

// Service locator (Dependency Injection)
import 'app/core/di/service_locator.dart';

// Core utilities
import 'app/core/utils/logger.dart';

// Notification services
import 'features/notifications/data/services/firebase_messaging_service.dart';

/// Top-level function to handle Firebase background messages
/// Must be a top-level function (cannot be a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('📬 Background notification received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
  }

  // Note: This runs in a separate isolate, so we can't access app state here
  // Background notifications are automatically shown by the system
}

void main() async {
  // Ensure that widget binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling
  _setupGlobalErrorHandling();

  // Set up system UI overlay style
  _setupSystemUIOverlayStyle();

  // Initialize logger
  AppLogger.init();
  AppLogger.info('🚀 Starting ${AppConfig.appName} v${AppConfig.appVersion}');

  try {
    // Initialize Firebase
    AppLogger.info('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up Firebase background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.info('✅ Firebase initialized successfully');

    // Initialize dependency injection
    await initServiceLocator();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    AppLogger.info('✅ App initialization completed successfully');

    // Run the app
    runApp(const PedidosApp());
  } catch (error, stackTrace) {
    AppLogger.error(
      '❌ App initialization failed',
      error: error,
      stackTrace: stackTrace,
    );

    // Run the app anyway with a fallback error screen
    runApp(AppInitializationError(error: error));
  }
}

/// Setup global error handling for Flutter framework errors
void _setupGlobalErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Handle other errors not caught by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Platform Error', error: error, stackTrace: stack);
    return true;
  };
}

/// Setup system UI overlay style
void _setupSystemUIOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// Main application widget
class PedidosApp extends StatelessWidget {
  const PedidosApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get ThemeController to observe theme changes
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        // App configuration
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,

        // Theme configuration - use dynamic themes from controller
        theme: themeController.lightTheme,
        darkTheme: themeController.darkTheme,
        themeMode: themeController.themeMode,

        // Localization configuration
        locale: const Locale('es', 'ES'),
        fallbackLocale: const Locale('en', 'US'),

        // Routing configuration
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        unknownRoute: GetPage(
          name: '/unknown',
          page: () => const UnknownRoutePage(),
        ),

        // Error handling
        builder: (context, widget) {
          // Handle errors in widget building
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            AppLogger.error(
              'Widget Error',
              error: errorDetails.exception,
              stackTrace: errorDetails.stack,
            );

            if (AppConfig.isDebugMode) {
              return ErrorWidget(errorDetails.exception);
            } else {
              return const AppErrorWidget();
            }
          };

          return widget ?? const SizedBox();
        },

        // Global navigation observers
        navigatorObservers: [AppNavigatorObserver()],

        // Performance optimization
        smartManagement: SmartManagement.full,

        // Transition configuration
        defaultTransition: Transition.cupertino,
        transitionDuration: AppConfig.animationDurationMedium,
      ),
    );
  }
}

/// Navigator observer for logging navigation events
class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    AppLogger.info('Navigation: Pushed ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppLogger.info('Navigation: Popped ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    AppLogger.info(
      'Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }
}

/// Error page for unknown routes
class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página no encontrada'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppPages.offAllNamed(AppRoutes.home),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppConfig.paddingLarge),
            Text(
              '404',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            const Text(
              'Página no encontrada',
              style: TextStyle(
                fontSize: AppConfig.headingFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            const Text(
              'La página que buscas no existe o ha sido movida.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppConfig.paddingLarge),
            ElevatedButton(
              onPressed: () => AppPages.offAllNamed(AppRoutes.home),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic error widget for widget build errors
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: AppConfig.errorColor),
              const SizedBox(height: AppConfig.paddingMedium),
              const Text(
                'Error inesperado',
                style: TextStyle(
                  fontSize: AppConfig.headingFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppConfig.paddingSmall),
              const Text(
                AppConfig.genericErrorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConfig.bodyFontSize,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              ElevatedButton(
                onPressed: () {
                  // Force app restart by navigating to splash
                  Get.offAllNamed(AppRoutes.splash);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error screen shown when app initialization fails
class AppInitializationError extends StatelessWidget {
  final Object error;

  const AppInitializationError({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppConfig.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConfig.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: AppConfig.errorColor,
                ),
                const SizedBox(height: AppConfig.paddingLarge),
                const Text(
                  'Error de inicialización',
                  style: TextStyle(
                    fontSize: AppConfig.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                const Text(
                  'La aplicación no pudo iniciarse correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppConfig.bodyFontSize,
                    color: Colors.grey,
                  ),
                ),
                if (AppConfig.isDebugMode) ...[
                  const SizedBox(height: AppConfig.paddingMedium),
                  Container(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(
                        AppConfig.borderRadius,
                      ),
                    ),
                    child: Text(
                      error.toString(),
                      style: const TextStyle(
                        fontSize: AppConfig.smallFontSize,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppConfig.paddingLarge),
                ElevatedButton(
                  onPressed: () {
                    // In a real app, you might want to restart the app
                    // For now, we'll just show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, reinicia la aplicación manualmente',
                        ),
                      ),
                    );
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
