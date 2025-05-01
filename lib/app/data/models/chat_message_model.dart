import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video } // Example message types

class ChatMessageModel {
  final String id; // Firestore document ID
  final String senderId;
  final String? ciphertextBase64; // ADDED: Encrypted message (Base64)
  final String? nonceBase64;
  final String? macBase64;
  final Timestamp timestamp;
  final String? attachmentUrl; // URL to the attachment in storage
  final String? attachmentType; // 'image' or 'file'
  final String? attachmentName; // Original filename
  final int? attachmentSize; // Size in bytes

  ChatMessageModel({
    required this.id,
    required this.senderId,
    this.ciphertextBase64,
    this.nonceBase64,
    this.macBase64,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    this.attachmentSize,
  });

  // Helper getters
  Uint8List? get ciphertextBytes =>
      ciphertextBase64 != null ? base64Decode(ciphertextBase64!) : null;
  Uint8List? get nonceBytes =>
      nonceBase64 != null ? base64Decode(nonceBase64!) : null;

  factory ChatMessageModel.fromJson(String id, Map<String, dynamic> json) {
    return ChatMessageModel(
      id: id,
      senderId: json['senderId'] as String? ?? '',
      ciphertextBase64: json['ciphertextBase64'] as String?,
      nonceBase64: json['nonceBase64'] as String?,
      macBase64: json['macBase64'] as String?,
      timestamp: json['timestamp'] as Timestamp? ?? Timestamp.now(),
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentType: json['attachmentType'] as String?,
      attachmentName: json['attachmentName'] as String?,
      attachmentSize: json['attachmentSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'ciphertextBase64': ciphertextBase64,
      'nonceBase64': nonceBase64,
      'macBase64': macBase64,
      'timestamp': timestamp,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'attachmentName': attachmentName,
      'attachmentSize': attachmentSize,
    };
  }
}
