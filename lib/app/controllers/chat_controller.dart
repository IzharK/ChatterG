import 'dart:async';
import 'dart:developer';
// import 'dart:io'; // TODO: Uncomment when file upload is needed

import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/data/models/chat_message_model.dart';
import 'package:chatter_jee/app/data/models/chat_room_model.dart';
import 'package:chatter_jee/app/data/providers/crypto_service.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
// import 'package:chatter_jee/app/data/providers/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as path; // TODO: Uncomment when file upload is needed

class DecryptedMessage {
  final String? text;
  final ChatMessageModel originalMessage;
  final bool decryptionFailed;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? attachmentName;

  DecryptedMessage({
    this.text,
    required this.originalMessage,
    this.decryptionFailed = false,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
  });
}

class ChatController extends GetxController {
  final String chatId;
  final _firestoreService = Get.find<FirestoreService>();
  final _authController = Get.find<AuthController>();
  final _cryptoService = Get.find<CryptoService>();
  // TODO: Uncomment when file upload is needed
  // final _storageService = Get.find<StorageService>();
  // final _imagePicker = ImagePicker();

  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxBool isDeleting = false.obs;

  final RxList<DecryptedMessage> decryptedMessages = <DecryptedMessage>[].obs;
  final RxBool isSessionKeyReady = false.obs;

  final TextEditingController messageTextController = TextEditingController();
  final Rx<ChatRoomModel?> currentChatRoom = Rx<ChatRoomModel?>(null);

  ChatController({required this.chatId});

  @override
  void onInit() {
    super.onInit();
    _fetchChatRoomDetails();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    isLoading.value = true;
    isSessionKeyReady.value = false;

    final sessionKey = await _cryptoService.getSessionKey(chatId);
    if (sessionKey != null) {
      isSessionKeyReady.value = true;
    } else {
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries && !isSessionKeyReady.value) {
        try {
          if (currentChatRoom.value != null &&
              !currentChatRoom.value!.isGroup) {
            final ownUserId = _authController.currentUserId;
            final otherMemberId = currentChatRoom.value!.members.firstWhere(
              (id) => id != ownUserId,
              orElse: () => '',
            );

            if (ownUserId != null && otherMemberId.isNotEmpty) {
              final recipientUser = await _firestoreService.getUser(
                otherMemberId,
              );
              if (recipientUser?.publicIdentityKeyBytes != null) {
                final recipientPublicKey = SimplePublicKey(
                  recipientUser!.publicIdentityKeyBytes!,
                  type: KeyPairType.x25519,
                );

                final newSessionKey = await _cryptoService
                    .establishAndStoreSessionKey(
                      chatId,
                      ownUserId,
                      recipientPublicKey,
                    );

                if (newSessionKey != null) {
                  isSessionKeyReady.value = true;
                  break;
                }
              }
            }
          }
        } catch (e) {
          // Handle error silently
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 1 * retryCount));
        }
      }
    }

    if (isSessionKeyReady.value) {
      _bindAndDecryptMessagesStream();
    } else {
      isLoading.value = false;
      Get.snackbar(
        "Encryption Error",
        "Cannot establish secure session for this chat.",
        duration: Duration(seconds: 10),
      );
    }

    isLoading.value = false;
  }

  Future<void> _fetchChatRoomDetails() async {
    isLoading.value = true;
    try {
      final chatRoom = await _firestoreService.getChatRoom(chatId);
      if (chatRoom != null) {
        currentChatRoom.value = chatRoom;
      } else {
        Get.snackbar(
          'Error',
          'Could not load chat details.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error loading chat: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;

  void _bindAndDecryptMessagesStream() {
    isLoading.value = true;
    final stream = _firestoreService.getMessagesStream(chatId);

    _messagesSubscription = stream.listen(
      (rawMessages) async {
        List<DecryptedMessage> newDecryptedList = [];
        for (var msg in rawMessages) {
          if (msg.ciphertextBase64 != null && msg.nonceBase64 != null) {
            final decryptedText = await _cryptoService.decryptMessage(
              chatId,
              msg.ciphertextBase64!,
              msg.nonceBase64!,
              msg.macBase64 ?? '',
            );
            newDecryptedList.add(
              DecryptedMessage(
                text: decryptedText,
                originalMessage: msg,
                decryptionFailed: decryptedText == null,
                attachmentUrl: msg.attachmentUrl,
                attachmentType: msg.attachmentType,
                attachmentName: msg.attachmentName,
              ),
            );
          } else {
            final bool hasOnlyAttachment =
                msg.attachmentUrl != null &&
                (msg.ciphertextBase64 == null || msg.ciphertextBase64!.isEmpty);
            newDecryptedList.add(
              DecryptedMessage(
                originalMessage: msg,
                text: hasOnlyAttachment ? "" : "[Invalid Data]",
                decryptionFailed: !hasOnlyAttachment,
                attachmentUrl: msg.attachmentUrl,
                attachmentType: msg.attachmentType,
                attachmentName: msg.attachmentName,
              ),
            );
          }
        }

        decryptedMessages.assignAll(newDecryptedList);

        if (isLoading.value) {
          isLoading.value = false;
        }
      },
      onError: (error) {
        isLoading.value = false;
      },
    );
  }

  Future<void> sendMessage() async {
    final text = messageTextController.text.trim();
    final userId = _authController.currentUserId;

    if (!isSessionKeyReady.value) {
      Get.snackbar(
        "Error",
        "Cannot send message. Secure session not established.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // TODO: Uncomment when file upload is needed
    // if ((text.isEmpty && _pendingAttachment.value == null) || userId == null) {
    //   return;
    // }
    if (text.isEmpty || userId == null) {
      return;
    }

    if (currentChatRoom.value == null) {
      log("Error: Cannot send message, chat room details not loaded.");
      return;
    }

    isSending.value = true;

    String? attachmentUrl;
    String? attachmentType;
    String? attachmentName;
    int? attachmentSize;

    // TODO: Uncomment attachment handling when file upload is needed
    // Handle attachment if present
    // if (_pendingAttachment.value != null) {
    //   final attachment = await _storageService.uploadAttachment(
    //     chatId,
    //     userId,
    //     _pendingAttachment.value!,
    //     pendingAttachmentType?.value ?? 'file',
    //   );
    //
    //   if (attachment != null) {
    //     attachmentUrl = attachment['url'];
    //     attachmentType = attachment['type'];
    //     attachmentName = attachment['name'];
    //     attachmentSize = attachment['size'];
    //   }
    // }

    // Only encrypt text if there is text to encrypt
    String? ciphertextBase64;
    String? nonceBase64;
    String? macBase64;

    if (text.isNotEmpty) {
      final encryptedData = await _cryptoService.encryptMessage(chatId, text);

      if (encryptedData == null) {
        Get.snackbar(
          "Error",
          "Failed to encrypt message.",
          snackPosition: SnackPosition.BOTTOM,
        );
        isSending.value = false;
        return;
      }

      ciphertextBase64 = encryptedData['ciphertext'];
      nonceBase64 = encryptedData['nonce'];
      macBase64 = encryptedData['mac'];
    }

    final newMessage = ChatMessageModel(
      id: '',
      senderId: userId,
      ciphertextBase64: ciphertextBase64,
      nonceBase64: nonceBase64,
      macBase64: macBase64,
      timestamp: Timestamp.now(),
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
    );

    try {
      await _firestoreService.sendMessage(
        chatId,
        newMessage,
        currentChatRoom.value!,
      );
      messageTextController.clear();
      // TODO: Uncomment when file upload is needed
      // clearPendingAttachment();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  // TODO: Uncomment attachment handling when file upload is needed
  // Add these properties for attachment handling
  // final Rx<File?> _pendingAttachment = Rx<File?>(null);
  // final RxString? pendingAttachmentType = RxString('');
  // final RxString _pendingAttachmentName = RxString('');
  //
  // bool get hasAttachment => _pendingAttachment.value != null;
  // String get attachmentName => _pendingAttachmentName.value;
  //
  // void clearPendingAttachment() {
  //   _pendingAttachment.value = null;
  //   pendingAttachmentType?.value = '';
  //   _pendingAttachmentName.value = '';
  // }
  //
  // Future<void> pickImage() async {
  //   final pickedFile = await _imagePicker.pickImage(
  //     source: ImageSource.gallery,
  //   );
  //
  //   if (pickedFile != null) {
  //     _pendingAttachment.value = File(pickedFile.path);
  //     pendingAttachmentType?.value = 'image';
  //     _pendingAttachmentName.value = path.basename(pickedFile.path);
  //   }
  // }
  //
  // Future<void> pickFile() async {
  //   final result = await FilePicker.platform.pickFiles();
  //
  //   if (result != null && result.files.single.path != null) {
  //     _pendingAttachment.value = File(result.files.single.path!);
  //     pendingAttachmentType?.value = 'file';
  //     _pendingAttachmentName.value = result.files.single.name;
  //   }
  // }

  Future<void> deleteChat(BuildContext context) async {
    if (!canCurrentUserDeleteChat) {
      Get.snackbar(
        'Permission Denied',
        'Only the chat creator can delete this chat.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    bool? confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Chat?'),
            content: const Text(
              'This will permanently delete this chat and all its messages. This action cannot be undone.\n\nNOTE: This only deletes the chat on your device. Other members will still see it.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    isDeleting.value = true;

    try {
      await _firestoreService.deleteChat(chatId);
      await _cryptoService.deleteSessionKey(chatId);

      if (context.mounted) {
        GoRouter.of(context).go('/');
      } else {
        Get.back();
      }

      Get.snackbar(
        'Success',
        'Chat deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete chat: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeleting.value = false;
    }
  }

  Future<void> deleteMessage(
    BuildContext context,
    DecryptedMessage message,
  ) async {
    final userId = _authController.currentUserId;

    // Check if user is the sender of the message
    if (userId != message.originalMessage.senderId) {
      SnackBar(
        content: Text(
          'You can only delete messages you sent.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      );
      return;
      // Get.snackbar(
      //   'Permission Denied',
      //   'You can only delete messages you sent.',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      // return;
    }

    bool? confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Message?'),
            content: const Text(
              'This will permanently delete this message. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    final messageId = message.originalMessage.id;
    final hasAttachment =
        message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty;

    try {
      // Delete from Firestore
      await _firestoreService.deleteMessage(chatId, messageId);

      // TODO: Uncomment when file upload is needed
      // If message has an attachment, delete it from Supabase storage
      // if (hasAttachment) {
      //   final attachmentPath = _extractStoragePathFromUrl(
      //     message.attachmentUrl!,
      //   );
      //   if (attachmentPath != null) {
      //     await _storageService.deleteAttachment(attachmentPath);
      //   }
      // }

      Get.snackbar(
        'Success',
        'Message deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete message: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool get canCurrentUserDeleteChat {
    final chatRoom = currentChatRoom.value;
    final currentUserId = _authController.currentUserId;

    if (chatRoom == null || currentUserId == null) {
      return false;
    }
    return chatRoom.createdBy == currentUserId;
  }

  // TODO: Uncomment when file upload is needed
  // Helper method to extract storage path from attachment URL
  // String? _extractStoragePathFromUrl(String url) {
  //   // Example URL format: https://supabase-url/storage/v1/object/public/chat-attachments/chats/chatId/attachments/fileId.ext
  //   try {
  //     final uri = Uri.parse(url);
  //     final pathSegments = uri.pathSegments;
  //
  //     // Find the index of 'chat-attachments' in the path
  //     final bucketIndex = pathSegments.indexOf('chat-attachments');
  //     if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
  //       // Return the path after 'chat-attachments'
  //       return pathSegments.sublist(bucketIndex + 1).join('/');
  //     }
  //     return null;
  //   } catch (e) {
  //     log('Error extracting storage path: $e');
  //     return null;
  //   }
  // }

  @override
  void onClose() {
    messageTextController.dispose();
    _messagesSubscription?.cancel();
    super.onClose();
  }
}
