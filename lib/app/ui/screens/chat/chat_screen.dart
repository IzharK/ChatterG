import 'dart:developer';

import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/controllers/chat_controller.dart';
import 'package:chatter_jee/app/data/models/chat_room_model.dart';
import 'package:chatter_jee/app/data/models/user_model.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:chatter_jee/app/ui/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({required this.chatId, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController controller;
  final AuthController authController = Get.find();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ChatController(chatId: widget.chatId),
      tag: widget.chatId,
    );
  }

  @override
  void dispose() {
    log(
      "Disposing ChatScreen and deleting controller for chatId: ${widget.chatId}",
    );
    Get.delete<ChatController>(tag: widget.chatId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildFloatingAppBar(context)),

                // --- Chat Messages Area ---
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Obx(() {
                    if (!controller.isSessionKeyReady.value &&
                        !controller.isLoading.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Cannot establish secure connection.",
                            style: TextStyle(color: AppColors.errorRed),
                          ),
                        ),
                      );
                    }
                    if (controller.isLoading.value &&
                        controller.decryptedMessages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (controller.decryptedMessages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            controller.isSessionKeyReady.value
                                ? "Send your first message!"
                                : "Waiting for secure session...",
                            style: const TextStyle(color: AppColors.textGrey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: controller.decryptedMessages.length,
                      itemBuilder: (context, index) {
                        final decryptedMsg =
                            controller.decryptedMessages[index];
                        final originalMsg = decryptedMsg.originalMessage;
                        final bool isMe =
                            originalMsg.senderId ==
                            authController.currentUserId;

                        String displayText;
                        bool hasError = false;
                        if (decryptedMsg.decryptionFailed) {
                          displayText = "[Decryption Failed]";
                          hasError = true;
                        } else if (decryptedMsg.text == null &&
                            decryptedMsg.attachmentUrl == null) {
                          displayText = "[Missing Data]";
                          hasError = true;
                        } else {
                          displayText = decryptedMsg.text ?? '';
                        }

                        return ContextMenuRegion(
                          contextMenu: ContextMenu(
                            boxDecoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            entries: [
                              MenuItem(
                                label: const Text(
                                  "Delete",
                                  style: TextStyle(color: AppColors.errorRed),
                                ),
                                icon: Icon(
                                  Icons.delete,
                                  color: AppColors.errorRed,
                                ),
                                value: 'delete',
                                onSelected:
                                    (val) => controller.deleteMessage(
                                      context,
                                      decryptedMsg,
                                    ),
                              ),
                            ],
                          ),
                          child: ChatBubble(
                            messageText: displayText,
                            timestamp: originalMsg.timestamp,
                            isMe: isMe,
                            hasError: hasError,
                            attachmentUrl: decryptedMsg.attachmentUrl,
                            attachmentType: decryptedMsg.attachmentType,
                            attachmentName: decryptedMsg.attachmentName,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          Obx(
            () =>
                controller.isLoading.value
                    ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: _buildMessageInput(
                        isSending: controller.isSending.value,
                        enabled:
                            controller.isSessionKeyReady.value &&
                            !controller.isSending.value,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: kToolbarHeight,
        left: 12.0,
        right: 12.0,
        bottom: 8.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.only(right: 5),
                icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                tooltip: 'Back',
                color: AppColors.textWhite,
                onPressed: () => context.pop(),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Text(
                        "...",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      );
                    }
                    final chatRoom = controller.currentChatRoom.value;
                    if (chatRoom == null) {
                      return const Text(
                        "...",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      );
                    }
                    if (chatRoom.isGroup) {
                      return Text(
                        chatRoom.groupName ?? 'Group',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    } else {
                      final otherUserId = chatRoom.members.firstWhere(
                        (id) => id != authController.currentUserId,
                        orElse: () => '',
                      );
                      return FutureBuilder<UserModel?>(
                        future: Get.find<FirestoreService>().getUser(
                          otherUserId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              "...",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textWhite,
                              ),
                            );
                          }
                          final displayName =
                              snapshot.data?.displayName ?? 'Chat';
                          return Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      );
                    }
                  }),
                  // Subtitle ("Secret chat")
                  Obx(() {
                    // Only show subtitle for 1-on-1 chats maybe?
                    final chatRoom = controller.currentChatRoom.value;
                    if (chatRoom != null && !chatRoom.isGroup) {
                      return const Text(
                        "Secret chat",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      );
                    } else {
                      return const SizedBox(
                        height: 2,
                      ); // Maintain some spacing if no subtitle
                    }
                  }),
                ],
              ),
            ),

            Obx(() {
              if (controller.isDeleting.value) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textWhite,
                    ),
                  ),
                );
              } else if (controller.canCurrentUserDeleteChat) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'Delete Chat',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 25,
                      color: AppColors.textWhite,
                    ),
                    color: AppColors.textGrey,
                    onPressed: () => controller.deleteChat(context),
                  ),
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      final chatRoom = controller.currentChatRoom.value;
                      if (chatRoom == null) return;

                      showModalBottomSheet(
                        context: context,
                        builder: (context) => ChatInfoSheet(chatRoom: chatRoom),
                      );
                    },
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput({required bool isSending, required bool enabled}) {
    // TODO: Uncomment when file upload is needed
    // final bool canSend =
    //     enabled &&
    //     (controller.messageTextController.text.isNotEmpty ||
    //         controller.hasAttachment);
    final bool canSend =
        enabled && controller.messageTextController.text.isNotEmpty;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: Uncomment when file upload is needed
            // // Show pending attachment if any
            // Obx(() {
            //   if (controller.hasAttachment) {
            //     return Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 12,
            //         vertical: 8,
            //       ),
            //       margin: const EdgeInsets.only(bottom: 8),
            //       decoration: BoxDecoration(
            //         color: AppColors.background,
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Row(
            //         children: [
            //           Icon(
            //             controller.pendingAttachmentType?.value == 'image'
            //                 ? Icons.image_outlined
            //                 : Icons.attach_file_outlined,
            //             color: AppColors.textGrey,
            //           ),
            //           const SizedBox(width: 8),
            //           Expanded(
            //             child: Text(
            //               controller.pendingAttachmentType?.value == 'image'
            //                   ? "Image Ready"
            //                   : "File Ready",
            //               style: const TextStyle(
            //                 color: AppColors.textWhite,
            //                 fontWeight: FontWeight.w500,
            //               ),
            //               overflow: TextOverflow.ellipsis,
            //             ),
            //           ),
            //           IconButton(
            //             icon: const Icon(
            //               Icons.close,
            //               color: AppColors.textGrey,
            //               size: 20,
            //             ),
            //             visualDensity: VisualDensity.compact,
            //             padding: EdgeInsets.zero,
            //             constraints: const BoxConstraints(),
            //             onPressed: controller.clearPendingAttachment,
            //           ),
            //         ],
            //       ),
            //     );
            //   }
            //   return const SizedBox.shrink();
            // }),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // TODO: Uncomment when file upload is needed
                // IconButton(
                //   icon: const Icon(
                //     Icons.attach_file,
                //     color: AppColors.textGrey,
                //   ),
                //   onPressed:
                //       enabled
                //           ? () {
                //             showModalBottomSheet(
                //               context: context,
                //               backgroundColor: AppColors.surface,
                //               builder:
                //                   (context) => AttachmentSheet(
                //                     onImageSelected: (_) {
                //                       context.pop();
                //                       controller.pickImage();
                //                     },
                //                     onFileSelected: (_) {
                //                       context.pop();
                //                       controller.pickFile();
                //                     },
                //                   ),
                //             );
                //           }
                //           : null,
                // ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: controller.messageTextController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.textGrey),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                      ),
                      style: const TextStyle(color: AppColors.textWhite),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      enabled: enabled,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),
                Material(
                  color:
                      (canSend && !isSending)
                          ? AppColors.primary
                          : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap:
                        (canSend && !isSending) ? controller.sendMessage : null,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child:
                          controller.isSending.value
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textBlack,
                                ),
                              )
                              : Icon(
                                Icons.send,
                                color:
                                    (canSend && !isSending)
                                        ? AppColors.textBlack
                                        : AppColors.primary,
                                size: 24,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatInfoSheet extends StatelessWidget {
  final ChatRoomModel chatRoom;

  const ChatInfoSheet({required this.chatRoom, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatRoom.isGroup ? 'Group Info' : 'Chat Info',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textWhite),
          ),
          const SizedBox(height: 16),
          if (chatRoom.isGroup) ...[
            Text(
              'Group Name: ${chatRoom.groupName}',
              style: TextStyle(color: AppColors.textWhite),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Members: ${chatRoom.members.length}',
            style: TextStyle(color: AppColors.textWhite),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO: Uncomment when file upload is needed
// class AttachmentSheet extends StatelessWidget {
//   final Function(String) onImageSelected;
//   final Function(String) onFileSelected;
//
//   const AttachmentSheet({
//     required this.onImageSelected,
//     required this.onFileSelected,
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             leading: const Icon(Icons.photo_library_outlined),
//             title: const Text('Photo or Video'),
//             onTap: () => onImageSelected('image'),
//           ),
//           ListTile(
//             leading: const Icon(Icons.attach_file_outlined),
//             title: const Text('File'),
//             onTap: () => onFileSelected('file'),
//           ),
//         ],
//       ),
//     );
//   }
// }
