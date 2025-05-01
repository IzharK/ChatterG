import 'package:chatter_jee/app/bindings/initial_binding.dart';
import 'package:chatter_jee/app/routes/app_router.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:chatter_jee/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://slyjmotssvhwdjvucovr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNseWptb3Rzc3Zod2RqdnVjb3ZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5MjgzOTQsImV4cCI6MjA2MTUwNDM5NH0.lkUXjwnJPrQe9GaUzW33TBeoCOI_Juh2q6cvqCJfpVU',
  );
  // Run initial bindings for core services/controllers
  InitialBinding().dependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _appRouter = Get.find<AppRouter>();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use GetMaterialApp.router for GoRouter integration
    return GetMaterialApp.router(
      title: 'Flutter Chat App',
      theme: buildDarkTheme(),
      debugShowCheckedModeBanner: false,
      // Router configuration
      routerDelegate: _appRouter.router.routerDelegate,
      routeInformationParser: _appRouter.router.routeInformationParser,
      routeInformationProvider: _appRouter.router.routeInformationProvider,
    );
  }
}
