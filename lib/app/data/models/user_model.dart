import 'dart:convert';
import 'dart:typed_data';

class UserModel {
  final String uid;
  final String email;
  final String? displayName; // Optional display name
  final String? photoUrl; // Optional photo URL
  final String? publicIdentityKeyBase64;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.publicIdentityKeyBase64,
  });

  // Helper to get public key bytes
  Uint8List? get publicIdentityKeyBytes {
    if (publicIdentityKeyBase64 != null) {
      try {
        return base64Decode(publicIdentityKeyBase64!);
      } catch (e) {
        print("Error decoding public key for $uid: $e");
        return null;
      }
    }
    return null;
  }

  // Factory constructor to create a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      publicIdentityKeyBase64: json['publicIdentityKeyBase64'] as String?,
    );
  }

  // Method to convert UserModel instance to JSON data
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'publicIdentityKeyBase64': publicIdentityKeyBase64,
    };
  }
}
