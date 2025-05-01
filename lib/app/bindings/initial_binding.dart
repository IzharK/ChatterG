import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/data/providers/auth_service.dart';
import 'package:chatter_jee/app/data/providers/crypto_service.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
import 'package:chatter_jee/app/data/providers/gemini_service.dart';
import 'package:chatter_jee/app/data/providers/storage_service.dart';
import 'package:chatter_jee/app/routes/app_router.dart';
import 'package:get/get.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // Core Services (Permanent)
    Get.put(AuthService(), permanent: true);
    Get.put(FirestoreService(), permanent: true);
    Get.put(CryptoService(), permanent: true);
    Get.put(StorageService(), permanent: true);
    Get.put(GeminiService(), permanent: true);

    // Get.find<GeminiService>().initializeGemini();

    // Core Controllers (Permanent)
    Get.put(AuthController(), permanent: true);

    // Router (should usually be permanent or globally accessible)
    Get.put(AppRouter(), permanent: true);
  }
}
