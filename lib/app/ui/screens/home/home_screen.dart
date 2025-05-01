import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/controllers/home_controller.dart';
import 'package:chatter_jee/app/data/models/chat_room_model.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:chatter_jee/app/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final controller = Get.put(HomeController());
  final authController = Get.find<AuthController>();

  HomeScreen({super.key});

  // Helper to get display data for a chat room
  Future<Map<String, dynamic>> _getChatRoomDisplayData(
    ChatRoomModel chatRoom,
  ) async {
    if (chatRoom.isGroup) {
      return {
        'name': chatRoom.groupName ?? 'Group Chat',
        'avatarUrl': chatRoom.groupIconUrl,
        'lastMessage': chatRoom.lastMessage,
        'timestamp': chatRoom.lastMessageTimestamp,
      };
    } else {
      final otherUserId = chatRoom.members.firstWhere(
        (id) => id != authController.currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isNotEmpty) {
        final user = await Get.find<FirestoreService>().getUser(otherUserId);
        return {
          'name': user?.displayName ?? 'Chat User',
          'avatarUrl': user?.photoUrl,
          'lastMessage': chatRoom.lastMessage,
          'timestamp': chatRoom.lastMessageTimestamp,
        };
      }
    }
    return {
      'name': 'Chat',
      'avatarUrl': null,
      'lastMessage': chatRoom.lastMessage ?? '',
      'timestamp': chatRoom.lastMessageTimestamp,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('ChatterG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async => await authController.signOut(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.chatRooms.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Always show content with Gemini chat pinned at top
        return Column(
          children: [
            // Pinned Gemini Chat
            _buildPinnedGeminiChat(context),

            // Divider between pinned chat and regular chats
            const Divider(height: 1, thickness: 0.5),

            // Regular chats list or empty state
            Expanded(
              child:
                  controller.chatRooms.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No chats yet.\nTap the "+" button to start a new chat or group!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                      : _buildChatList(),
            ),
          ],
        );
      }),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          tooltip: 'New Chat',
          child: const Icon(Icons.add),
          onPressed: () => context.go('/new-chat'),
        ),
      ),
    );
  }

  // Pinned Gemini Chat Widget
  Widget _buildPinnedGeminiChat(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/gemini'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: AppColors.surface.withValues(alpha: 0.3),
        child: Row(
          children: [
            // Gemini Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/google-gemini-icon.svg',
                  height: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Chat with Gemini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ask me anything!',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Chevron icon
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  // Regular Chat List Widget
  Widget _buildChatList() {
    return ListView.separated(
      itemCount: controller.chatRooms.length,
      separatorBuilder:
          (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.surface.withOpacity(0.5), // Subtle divider
            indent: 80, // Indent past avatar + padding
          ),
      itemBuilder: (context, index) {
        final chatRoom = controller.chatRooms[index];
        // Use FutureBuilder to fetch user/group details asynchronously
        return FutureBuilder<Map<String, dynamic>>(
          future: _getChatRoomDisplayData(chatRoom),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              // Show a placeholder while loading user data
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.surface,
                  radius: 25,
                ),
                title: Container(height: 16, color: AppColors.surface),
                subtitle: Container(
                  height: 12,
                  color: AppColors.surface.withOpacity(0.7),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              // Handle error or missing data case
              return ListTile(title: Text("Error loading chat info"));
            }

            final data = snapshot.data!;
            final String name = data['name'];
            final String? avatarUrl = data['avatarUrl'];
            final String lastMessage = data['lastMessage'] ?? "";
            final Timestamp? timestamp = data['timestamp'];

            // Build the actual ListTile
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.surface, // Placeholder color
                backgroundImage:
                    (avatarUrl != null)
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                child:
                    (avatarUrl == null)
                        ? const Icon(
                          Icons.person,
                          color: AppColors.textGrey,
                        ) // Fallback icon
                        : null,
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                lastMessage,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing:
                  timestamp != null
                      ? Text(
                        Helpers.formatTimestamp(timestamp),
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      )
                      : null,
              onTap: () => context.go('/chat/${chatRoom.id}'),
            );
          },
        );
      },
    );
  }
}
