import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:chatter_jee/app/data/models/user_model.dart';
import 'package:chatter_jee/app/data/providers/auth_service.dart';
import 'package:chatter_jee/app/data/providers/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/providers/crypto_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find();
  final FirestoreService _firestoreService = Get.find();
  final _cryptoService = Get.put(CryptoService());

  final ValueNotifier<User?> firebaseUserNotifier = ValueNotifier<User?>(null);
  final Rx<UserModel?> _firestoreUserInternal = Rx<UserModel?>(null);
  final ValueNotifier<UserModel?> firestoreUserNotifier =
      ValueNotifier<UserModel?>(null);
  final RxBool isLoading = false.obs;

  Rx<UserModel?> get firestoreUser => _firestoreUserInternal;

  String? get currentUserId => _authService.currentUser?.uid;

  final hasCompletedInitialAuthCheckNotifier = ValueNotifier<bool>(false);
  bool get hasCompletedInitialAuthCheck =>
      hasCompletedInitialAuthCheckNotifier.value;

  @override
  void onReady() {
    super.onReady();
    ever(_authService.firebaseUser, (User? fbUser) {
      if (firebaseUserNotifier.value?.uid != fbUser?.uid ||
          (firebaseUserNotifier.value == null && fbUser != null) ||
          (firebaseUserNotifier.value != null && fbUser == null)) {
        firebaseUserNotifier.value = fbUser;
        _handleAuthChanged(fbUser);
      } else {
        log(
          "AuthController: Redundant auth state change detected, skipping _handleAuthChanged.",
        );
      }
    });

    ever(_firestoreUserInternal, (UserModel? fsUser) {
      if (firestoreUserNotifier.value?.uid != fsUser?.uid ||
          (firestoreUserNotifier.value == null && fsUser != null) ||
          (firestoreUserNotifier.value != null && fsUser == null)) {
        firestoreUserNotifier.value = fsUser;
      }
    });

    final initialAuthUser = _authService.firebaseUser.value;
    log(
      "AuthController: Processing initial auth state -> ${initialAuthUser?.uid}",
    );
    firebaseUserNotifier.value = initialAuthUser;
    _handleAuthChanged(initialAuthUser);
    if (!hasCompletedInitialAuthCheckNotifier.value) {
      hasCompletedInitialAuthCheckNotifier.value = true;
      log(
        'AuthController: Initial auth check completed. ${hasCompletedInitialAuthCheckNotifier.value}',
      );
      hasCompletedInitialAuthCheckNotifier.notifyListeners();
    }
  }

  void _handleAuthChanged(User? firebaseUser) {
    log("AuthController: Firebase auth state changed -> ${firebaseUser?.uid}");
    if (firebaseUser != null) {
      _fetchAndSetupUser(firebaseUser.uid);
    } else {
      _firestoreUserInternal.value = null;
    }
  }

  Future<void> _fetchAndSetupUser(String userId) async {
    final User? currentAuthUser = _authService.currentUser;
    if (currentAuthUser == null || currentAuthUser.uid != userId) {
      _firestoreUserInternal.value = null;
      return;
    }

    UserModel? user;
    bool updateRequired = false;
    bool createRequired = false;
    String? storedPubKeyB64;

    try {
      user = await _firestoreService.getUser(userId);

      if (user == null) {
        createRequired = true;
        var keyPair = await _cryptoService.generateAndStoreIdentityKeys(userId);
        final pubKey = await keyPair.extractPublicKey();
        storedPubKeyB64 = base64Encode(pubKey.bytes);

        user = UserModel(
          uid: userId,
          email: currentAuthUser.email ?? 'unknown@email.com',
          displayName: currentAuthUser.displayName,
          publicIdentityKeyBase64: storedPubKeyB64,
          photoUrl: currentAuthUser.photoURL,
        );
      } else {
        var keyPair = await _cryptoService.getIdentityKeyPair(userId);

        if (keyPair == null) {
          keyPair = await _cryptoService.generateAndStoreIdentityKeys(userId);
          final pubKey = await keyPair.extractPublicKey();
          storedPubKeyB64 = base64Encode(pubKey.bytes);
          if (user.publicIdentityKeyBase64 == null ||
              user.publicIdentityKeyBase64 != storedPubKeyB64) {
            updateRequired = true;
          }
        } else {
          final pubKey = await keyPair.extractPublicKey();
          storedPubKeyB64 = base64Encode(pubKey.bytes);
          if (user.publicIdentityKeyBase64 == null ||
              user.publicIdentityKeyBase64 != storedPubKeyB64) {
            updateRequired = true;
          }
        }
      }

      if (createRequired) {
        try {
          await _firestoreService.createUser(user);
        } catch (e) {
          user = null;
        }
      } else if (updateRequired) {
        try {
          await _firestoreService.updateUser(userId, {
            'publicIdentityKeyBase64': storedPubKeyB64,
          });
          user = user.copyWith(publicIdentityKeyBase64: storedPubKeyB64);
        } catch (e) {
          log("AuthController: Error updating user: $e");
        }
      }

      _firestoreUserInternal.value = user;
    } catch (error) {
      _firestoreUserInternal.value = user;
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    await _authService.signInWithEmailPassword(email, password);
    isLoading.value = false;
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
  ) async {
    isLoading.value = true;
    final userCredential = await _authService.registerWithEmailPassword(
      email,
      password,
    );
    if (userCredential?.user != null) {
      final userId = userCredential!.user!.uid;

      final keyPair = await _cryptoService.generateAndStoreIdentityKeys(userId);
      final pubKeyBytes = (await keyPair.extractPublicKey()).bytes;
      final pubKeyBase64 = base64Encode(pubKeyBytes);

      final newUser = UserModel(
        uid: userId,
        email: email,
        displayName: displayName,
        publicIdentityKeyBase64: pubKeyBase64,
      );

      await _firestoreService.createUser(newUser);
      _firestoreUserInternal.value = newUser;
    }
    isLoading.value = false;
  }

  Future<void> signOut() async {
    isLoading.value = true;
    await _authService.signOut();
    log("AuthController: Signing out.");
    isLoading.value = false;
  }

  @override
  void onClose() {
    log("AuthController closing. Disposing ValueNotifier.");
    firebaseUserNotifier.dispose();
    firestoreUserNotifier.dispose();
    super.onClose();
  }
}

extension UserModelCopy on UserModel {
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? publicIdentityKeyBase64,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      publicIdentityKeyBase64:
          publicIdentityKeyBase64 ?? this.publicIdentityKeyBase64,
    );
  }
}
