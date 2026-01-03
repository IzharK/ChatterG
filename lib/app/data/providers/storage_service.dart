import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService extends GetxService {
  late final _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  Future<Map<String, dynamic>?> uploadAttachment(
    String chatId,
    String userId,
    File file,
    String type,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        log(
          'User not authenticated with Supabase, attempting anonymous sign-in',
        );
        try {
          // Sign in anonymously with Supabase
          await _supabase.auth.signInAnonymously();
          log('Successfully signed in anonymously to Supabase');
        } catch (authError) {
          log('Failed to sign in anonymously: $authError');
          Get.snackbar(
            'Authentication Error',
            'Unable to authenticate with storage service',
            snackPosition: SnackPosition.BOTTOM,
          );
          return null;
        }
      }

      final fileName = path.basename(file.path);
      final extension = path.extension(fileName);
      final uniqueId = _uuid.v4();
      final storagePath = 'chats/$chatId/attachments/$uniqueId$extension';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from('chat-attachments')
          .upload(storagePath, file);

      // Get public URL for the uploaded file
      final downloadUrl = _supabase.storage
          .from('chat-attachments')
          .getPublicUrl(storagePath);

      final fileSize = await file.length();

      return {
        'url': downloadUrl,
        'type': type,
        'name': fileName,
        'size': fileSize,
      };
    } catch (e, stackTrace) {
      log('Upload error: $e');
      log('Stack trace: $stackTrace');

      // Handle the specific RLS policy error
      if (e is StorageException && e.statusCode == '403') {
        Get.snackbar(
          'Permission Error',
          'You don\'t have permission to upload files. Please check your Supabase configuration.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Use a null-safe way to show the snackbar to avoid the null check error
        try {
          Get.snackbar(
            'Error',
            'Failed to upload attachment: ${e.toString()}',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (snackbarError) {
          log('Error showing snackbar: $snackbarError');
        }
      }
      return null;
    }
  }

  Future<bool> deleteAttachment(String storagePath) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        log(
          'User not authenticated with Supabase, attempting anonymous sign-in',
        );
        try {
          // Sign in anonymously with Supabase
          await _supabase.auth.signInAnonymously();
          log('Successfully signed in anonymously to Supabase');
        } catch (authError) {
          log('Failed to sign in anonymously: $authError');
          return false;
        }
      }

      // Clean up the storage path if it's a full URL
      if (storagePath.startsWith('http')) {
        // Extract the path from URL
        final uri = Uri.parse(storagePath);
        final pathSegments = uri.pathSegments;

        // Find the index of 'chat-attachments' in the path
        final bucketIndex = pathSegments.indexOf('chat-attachments');
        if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
          // Get the path after 'chat-attachments'
          storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
          log('Extracted storage path from URL: $storagePath');
        } else {
          log('Could not extract storage path from URL: $storagePath');
          return false;
        }
      }

      log('Attempting to delete file at path: $storagePath');

      // Delete file from Supabase Storage
      await _supabase.storage.from('chat-attachments').remove([storagePath]);

      log('Successfully deleted attachment: $storagePath');
      return true;
    } catch (e) {
      log('Error deleting attachment: $e');
      Get.snackbar(
        'Storage Error',
        'Failed to delete attachment: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
