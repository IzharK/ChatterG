import 'dart:developer';

import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/data/models/chat_room_model.dart';
import 'package:chatter_jee/app/data/models/user_model.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
import 'package:chatter_jee/app/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatListTile extends StatefulWidget {
  final ChatRoomModel chatRoom;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chatRoom, required this.onTap});

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile> {
  final _firestoreService = Get.find<FirestoreService>();
  final _authController = Get.find<AuthController>();
  UserModel? _otherUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserDataIfNeeded();
  }

  Future<void> _fetchOtherUserDataIfNeeded() async {
    // Only fetch if it's a 1-on-1 chat and we haven't fetched yet
    if (!widget.chatRoom.isGroup && _otherUser == null) {
      final currentUserId = _authController.currentUserId;
      if (currentUserId == null) return;

      final otherUserId = widget.chatRoom.members.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          final user = await _firestoreService.getUser(otherUserId);
          if (mounted) {
            setState(() {
              _otherUser = user;
              _isLoading = false;
            });
          }
        } catch (e) {
          log("Error fetching user for chat tile: $e");
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Chat'; // Default title
    Widget leading = CircleAvatar(
      // Default avatar
      backgroundColor: Colors.grey[400],
      child: const Icon(Icons.chat_bubble, color: Colors.white),
    );

    if (widget.chatRoom.isGroup) {
      title = widget.chatRoom.groupName ?? 'Group Chat';
      leading = CircleAvatar(
        backgroundColor: Colors.blue[400],
        child: const Icon(Icons.group, color: Colors.white),
      );
    } else {
      if (_isLoading) {
        title = 'Loading...';
        leading = const CircleAvatar(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      } else if (_otherUser != null) {
        title = _otherUser!.displayName ?? _otherUser!.email;
        leading = CircleAvatar(
          backgroundColor: Colors.teal[400],
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: TextStyle(color: Colors.white),
          ),
        );
      } else {
        title = 'Chat User';
        leading = CircleAvatar(
          backgroundColor: Colors.grey[400],
          child: const Icon(Icons.person, color: Colors.white),
        );
      }
    }

    return ListTile(
      leading: leading,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        widget.chatRoom.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Text(
        Helpers.formatTimestamp(widget.chatRoom.lastMessageTimestamp),
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      onTap: widget.onTap,
    );
  }
}
