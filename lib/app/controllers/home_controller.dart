import 'dart:developer';

import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/data/models/chat_room_model.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final _firestoreService = Get.find<FirestoreService>();
  final _authController = Get.find<AuthController>();

  final RxList<ChatRoomModel> chatRooms = <ChatRoomModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _bindChatRoomsStream();
  }

  void _bindChatRoomsStream() {
    final userId = _authController.currentUserId;
    if (userId != null) {
      isLoading.value = true;
      chatRooms.bindStream(_firestoreService.getChatRoomsStream(userId));
      once(chatRooms, (_) => isLoading.value = false);
      Future.delayed(const Duration(seconds: 3), () {
        if (isLoading.value) isLoading.value = false;
      });
    } else {
      isLoading.value = false;
      log("Home Controller: User not logged in.");
    }
  }

  @override
  void onReady() {
    super.onReady();
    ever(_authController.firestoreUser, (_) => _bindChatRoomsStream());
  }
}
