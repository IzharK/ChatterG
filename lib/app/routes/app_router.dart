import 'dart:developer';

import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/ui/screens/auth/login_screen.dart';
import 'package:chatter_jee/app/ui/screens/auth/register_screen.dart';
import 'package:chatter_jee/app/ui/screens/chat/chat_screen.dart';
import 'package:chatter_jee/app/ui/screens/gemini/gemini_chat_screen.dart';
import 'package:chatter_jee/app/ui/screens/home/home_screen.dart';
import 'package:chatter_jee/app/ui/screens/home/user_selection_screen.dart';
import 'package:chatter_jee/app/ui/screens/settings/settings_screen.dart';
import 'package:chatter_jee/app/ui/screens/shell_scaffold.dart';
import 'package:chatter_jee/app/ui/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final authController = Get.find<AuthController>();

  late final GoRouter router = GoRouter(
    refreshListenable: Listenable.merge([
      authController.firebaseUserNotifier,
      authController.firestoreUserNotifier,
      authController.hasCompletedInitialAuthCheckNotifier,
    ]),

    initialLocation: '/splash',

    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => RegisterScreen()),
      GoRoute(path: '/gemini', builder: (context, state) => GeminiChatScreen()),
      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'];
          if (chatId == null) {
            return const Scaffold(body: Center(child: Text("Invalid Chat ID")));
          }
          return ChatScreen(chatId: chatId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                ShellScaffold(navigationShell: navigationShell),
        branches: [
          // Home branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'new-chat',
                    builder: (context, state) => UserSelectionScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text("Profile Screen")),
                    ),
              ),
            ],
          ),

          // Settings branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  // Add any settings sub-routes here if needed
                ],
              ),
            ],
          ),
        ],
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final firebaseAuthUser = authController.firebaseUserNotifier.value;
      final appUser = authController.firestoreUserNotifier.value;
      final appLoggedIn = appUser != null;

      final String currentLocation = state.uri.toString();
      final loggingIn = currentLocation == '/login';
      final registering = currentLocation == '/register';
      final splashing = currentLocation == '/splash';

      log(
        "Redirect Check: appLoggedIn=$appLoggedIn, fbUser=${firebaseAuthUser?.uid}, location=$currentLocation",
      );

      if (splashing) {
        log(
          'hasCompletedInitialAuthCheck=${authController.hasCompletedInitialAuthCheck}',
        );

        if (firebaseAuthUser != null) {
          log("Redirecting from Splash to / (User logged in)");
          return '/';
        }

        if (authController.hasCompletedInitialAuthCheck) {
          log(
            "Redirecting from Splash to /login (No user, auth check complete)",
          );
          return '/login';
        }

        log("Staying on Splash - Waiting for auth check to complete");
        return null;
      }

      if (!appLoggedIn && !loggingIn && !registering) {
        log("Redirecting to /login (not logged in, accessing protected route)");
        return '/login';
      }

      if (appLoggedIn && (loggingIn || registering)) {
        log("Redirecting to / (logged in, accessing auth route)");
        return '/';
      }

      return null;
    },

    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
            child: Text('Page not found: ${state.error?.toString()}'),
          ),
        ),
  );
}
