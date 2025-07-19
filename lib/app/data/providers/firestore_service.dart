import 'dart:developer';

import 'package:chatter_jee/app/data/models/chat_message_model.dart';
import 'package:chatter_jee/app/data/models/chat_room_model.dart';
import 'package:chatter_jee/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Operations ---
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      Get.snackbar('Firestore Error', 'Failed to create user: ${e.toString()}');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      Get.snackbar('Firestore Error', 'Failed to get user: ${e.toString()}');
      return null;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      log("FirestoreService Error updating user $uid: $e");
      rethrow;
    }
  }

  Stream<List<UserModel>> getAllUsersStream(String currentUserId) {
    return _db
        .collection('chats')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((chatSnapshot) async {
      final allUserIds = chatSnapshot.docs
          .map((doc) => List<String>.from(doc.data()['members']))
          .expand((id) => id)
          .toSet();

      allUserIds.remove(currentUserId);

      final userFutures = allUserIds.map((userId) => getUser(userId)).toList();
      final users = await Future.wait(userFutures);
      return users.where((user) => user != null).cast<UserModel>().toList();
    });
  }

  Future<ChatRoomModel?> getChatRoom(String chatId) async {
    try {
      final docSnapshot = await _db.collection('chats').doc(chatId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ChatRoomModel.fromJson(docSnapshot.id, docSnapshot.data()!);
      } else {
        log("FirestoreService: Chat room with ID $chatId not found.");
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Firestore Error',
        'Failed to get chat room details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      log("FirestoreService Error getting chat room $chatId: $e");
      return null;
    }
  }

  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    return _db
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatRoomModel.fromJson(doc.id, doc.data()))
              .toList();
        });
  }

  Future<String?> createChatRoom(ChatRoomModel chatRoom) async {
    try {
      final docRef = await _db.collection('chats').add(chatRoom.toJson());
      return docRef.id;
    } catch (e) {
      Get.snackbar('Firestore Error', 'Failed to create chat: ${e.toString()}');
      return null;
    }
  }

  Future<void> updateChatRoom(String chatId, Map<String, dynamic> data) async {
    try {
      await _db.collection('chats').doc(chatId).update(data);
    } catch (e) {
      Get.snackbar('Firestore Error', 'Failed to update chat: ${e.toString()}');
    }
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessageModel.fromJson(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> sendMessage(
    String chatId,
    ChatMessageModel message,
    ChatRoomModel chatRoom,
  ) async {
    try {
      final WriteBatch batch = _db.batch();

      final messageRef =
          _db.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(messageRef, message.toJson());

      final chatRef = _db.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': "[Encrypted Message]",
        'lastMessageTimestamp': message.timestamp,
        'lastMessageSenderId': message.senderId,
      });

      await batch.commit();
    } catch (e) {
      Get.snackbar(
        'Firestore Error',
        'Failed to send message: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
    log(
      "FirestoreService: Attempting to delete chat $chatId and its messages.",
    );
    try {
      final WriteBatch batch = _db.batch();

      final messagesSnapshot =
          await _db
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();
      int messageCount = 0;
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
        messageCount++;
      }
      log(
        "FirestoreService: Prepared batch delete for $messageCount messages in chat $chatId.",
      );

      final chatDocRef = _db.collection('chats').doc(chatId);
      batch.delete(chatDocRef);
      log("FirestoreService: Prepared batch delete for chat document $chatId.");

      await batch.commit();
      log(
        "FirestoreService: Successfully deleted chat $chatId and $messageCount messages.",
      );
    } catch (e, s) {
      log("FirestoreService Error: Failed to delete chat $chatId: $e");
      log("StackTrace: $s");

      rethrow;
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    log(
      "FirestoreService: Attempting to delete message $messageId from chat $chatId.",
    );
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      log(
        "FirestoreService: Successfully deleted message $messageId from chat $chatId.",
      );
    } catch (e, s) {
      log("FirestoreService Error: Failed to delete message $messageId: $e");
      log("StackTrace: $s");
      rethrow;
    }
  }
}
