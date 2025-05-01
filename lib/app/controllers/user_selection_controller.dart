import 'dart:developer';

import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/data/models/chat_room_model.dart';
import 'package:chatter_jee/app/data/models/user_model.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../data/providers/crypto_service.dart';

class UserSelectionController extends GetxController {
  final FirestoreService _firestoreService = Get.find();
  final AuthController _authController = Get.find();
  final CryptoService _cryptoService = Get.find();

  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxList<UserModel> selectedUsers = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isCreatingChat = false.obs;

  final TextEditingController groupNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _bindUsersStream();
  }

  void _bindUsersStream() {
    final currentUserId = _authController.currentUserId;
    if (currentUserId != null) {
      isLoading.value = true;
      allUsers.bindStream(_firestoreService.getAllUsersStream(currentUserId));
      once(allUsers, (_) => isLoading.value = false);
      Future.delayed(const Duration(seconds: 3), () {
        if (isLoading.value) isLoading.value = false;
      });
    } else {
      isLoading.value = false;
      log("User Selection Controller: User not logged in.");
    }
  }

  void toggleUserSelection(UserModel user) {
    final bool wasSelected = selectedUsers.contains(user);

    if (wasSelected) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }

    update();
  }

  bool isSelected(UserModel user) {
    return selectedUsers.contains(user);
  }

  Future<void> createChat(BuildContext context) async {
    final currentUser = _authController.firestoreUser.value;
    if (currentUser == null) {
      Get.snackbar("Error", "User data not loaded. Please try again.");
      return;
    }
    if (selectedUsers.isEmpty) {
      Get.snackbar("Info", "Please select a user to chat with.");
      return;
    }

    final currentUserId = currentUser.uid;
    isCreatingChat.value = true;

    final memberIds = [currentUserId, ...selectedUsers.map((u) => u.uid)];
    final isGroup = selectedUsers.length > 1;

    SimplePublicKey? recipientPublicKeyForSetup;

    if (!isGroup) {
      final otherUser = selectedUsers.first;
      final recipientPublicKeyBytes = otherUser.publicIdentityKeyBytes;

      if (recipientPublicKeyBytes == null) {
        Get.snackbar(
          "Error",
          "Cannot start encrypted chat. Recipient's key is missing.",
        );
        isCreatingChat.value = false;
        return;
      }
      try {
        recipientPublicKeyForSetup = SimplePublicKey(
          recipientPublicKeyBytes,
          type: KeyPairType.x25519,
        );
      } catch (e) {
        Get.snackbar("Error", "Invalid recipient key format.");
        isCreatingChat.value = false;
        return;
      }
    }

    final groupName = isGroup ? groupNameController.text.trim() : null;

    if (isGroup && (groupName == null || groupName.isEmpty)) {
      Get.snackbar('Error', 'Please enter a group name.');
      isCreatingChat.value = false;
      return;
    }

    final newChatRoom = ChatRoomModel(
      id: '',
      isGroup: isGroup,
      members: memberIds,
      groupName: groupName,
      lastMessage: "Chat created",
      lastMessageSenderId: currentUserId,
      lastMessageTimestamp: Timestamp.now(),
      createdBy: currentUserId,
    );

    log('Prepared new ChatRoomModel: ${newChatRoom.toJson()}');

    try {
      final chatId = await _firestoreService.createChatRoom(newChatRoom);
      log('Firestore returned chatId: $chatId');

      if (chatId != null) {
        if (!isGroup && recipientPublicKeyForSetup != null) {
          final sessionKey = await _cryptoService.establishAndStoreSessionKey(
            chatId,
            currentUserId,
            recipientPublicKeyForSetup,
          );

          if (sessionKey == null) {
            log('Failed to establish session key for chat $chatId');
          }
        }

        isCreatingChat.value = false;
        context.go('/chat/$chatId');
      } else {
        isCreatingChat.value = false;
        Get.snackbar('Error', 'Failed to create chat room.');
      }
    } catch (e) {
      isCreatingChat.value = false;
      Get.snackbar('Error', 'Error creating chat: ${e.toString()}');
    }
  }
}
