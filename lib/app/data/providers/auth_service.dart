import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Rx<User?> firebaseUser = Rx<User?>(null);
  Stream<User?> get userChanges => _firebaseAuth.authStateChanges();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(userChanges);
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      log("!!! FirebaseAuthException during SIGN IN !!!");
      log("Code: ${e.code}");
      log("Message: ${e.message}");
      Get.snackbar(
        'Login Error',
        e.message ?? 'Unknown error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      log("!!! UNEXPECTED Exception during SIGN IN !!!");
      log("Type: ${e.runtimeType}");
      log("Error: ${e.toString()}");
      Get.snackbar(
        'Login Error',
        'An unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<UserCredential?> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      log("Attempting registration for: $email");
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      log("!!! FirebaseAuthException during REGISTRATION !!!");
      log("Code: ${e.code}");
      log("Message: ${e.message}");
      Get.snackbar(
        'Registration Error',
        e.message ?? 'Unknown error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      log("!!! UNEXPECTED Exception during REGISTRATION !!!");
      log("Type: ${e.runtimeType}");
      log("Error: ${e.toString()}");
      Get.snackbar(
        'Registration Error',
        'An unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      Get.snackbar(
        'Sign Out Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
