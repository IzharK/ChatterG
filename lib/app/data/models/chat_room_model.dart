import 'package:chatter_jee/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id; // Firestore document ID
  final bool isGroup;
  final List<String> members; // List of user UIDs
  final String? groupName;
  final String? groupIconUrl;
  final String? lastMessage;
  final Timestamp? lastMessageTimestamp;
  final String? lastMessageSenderId;
  final String? createdBy;
  // Add other fields like createdBy, createdAt if needed

  ChatRoomModel({
    required this.id,
    required this.isGroup,
    required this.members,
    this.groupName,
    this.groupIconUrl,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.lastMessageSenderId,
    this.createdBy,
  });

  factory ChatRoomModel.fromJson(String id, Map<String, dynamic> json) {
    return ChatRoomModel(
      id: id,
      isGroup: json['isGroup'] as bool? ?? false,
      members: List<String>.from(json['members'] as List<dynamic>? ?? []),
      groupName: json['groupName'] as String?,
      groupIconUrl: json['groupIconUrl'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] as Timestamp?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Don't include ID when writing usually
      'isGroup': isGroup,
      'members': members,
      'groupName': groupName,
      'groupIconUrl': groupIconUrl,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'lastMessageSenderId': lastMessageSenderId,
      'createdBy': createdBy,
      // Add 'createdAt': FieldValue.serverTimestamp() on creation if needed
    };
  }

  // Helper to get the name of the other user in a 1-on-1 chat
  // Requires fetching user data separately based on the other UID
  // Or store names directly in the membersMap: {'uid1': 'name1', 'uid2': 'name2'}
  String getChatDisplayName(String currentUserId, List<UserModel> allUsers) {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    } else {
      final otherUserId = members.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isNotEmpty) {
        final otherUser = allUsers.firstWhere(
          (user) => user.uid == otherUserId,
          orElse: () => UserModel(uid: '', email: 'Unknown'),
        );
        return otherUser.displayName ?? otherUser.email;
      }
      return 'Chat'; // Fallback
    }
  }
}
