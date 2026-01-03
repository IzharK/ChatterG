import 'package:chatter_jee/app/bindings/initial_binding.dart';
import 'package:chatter_jee/app/routes/app_router.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:chatter_jee/firebase_options.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO: Initialize Supabase when file upload is needed
  // See FILE_UPLOAD_SETUP.md for detailed instructions
  // await Supabase.initialize(
  //   url: 'https://your-supabase-url.supabase.co',
  //   anonKey: 'your-supabase-anon-key',
  // );

  // Run initial bindings for core services/controllers
  InitialBinding().dependencies();
  runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => MyApp()));
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
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      // Router configuration
      routerDelegate: _appRouter.router.routerDelegate,
      routeInformationParser: _appRouter.router.routeInformationParser,
      routeInformationProvider: _appRouter.router.routeInformationProvider,
    );
  }
}
