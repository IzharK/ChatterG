import 'dart:io';

import 'package:chatter_jee/app/data/providers/gemini_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class GeminiMessage {
  final String id;
  final String text;
  final bool isUser;
  final Timestamp timestamp;
  final List<File>? images;
  final List<File>? files;

  GeminiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.images,
    this.files,
  });
}

class GeminiController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final TextEditingController messageController = TextEditingController();
  final RxList<GeminiMessage> messages = <GeminiMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasApiKey = false.obs;

  // Selected files and images
  final RxList<File> selectedImages = <File>[].obs;
  final RxList<File> selectedFiles = <File>[].obs;

  // Model selection
  Rx<GeminiModel> get selectedModel => _geminiService.selectedModel;
  RxList<GeminiModel> get availableModels => _geminiService.availableModels;

  // Token usage metrics
  RxInt get usedTokens => _geminiService.usedTokens;
  RxInt get totalTokens => _geminiService.totalTokens;

  @override
  void onInit() {
    super.onInit();
    _checkApiKey();
    _loadInitialMessage();
    _loadModels();
  }

  Future<void> _loadModels() async {
    await _geminiService.loadSelectedModel();
    await _geminiService.fetchAvailableModels();
  }

  void selectModel(GeminiModel model) {
    _geminiService.saveSelectedModel(model);
  }

  Future<void> _checkApiKey() async {
    hasApiKey.value = await _geminiService.hasApiKey();
    if (hasApiKey.value) {}
  }

  void _loadInitialMessage() {
    if (messages.isEmpty) {
      messages.add(
        GeminiMessage(
          id: const Uuid().v4(),
          text:
              'Hello! I\'m Gemini, an AI assistant. How can I help you today?',
          isUser: false,
          timestamp: Timestamp.now(),
        ),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && selectedImages.isEmpty && selectedFiles.isEmpty)
      return;

    final userMessage = GeminiMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: Timestamp.now(),
      images:
          selectedImages.isNotEmpty ? List<File>.from(selectedImages) : null,
      files: selectedFiles.isNotEmpty ? List<File>.from(selectedFiles) : null,
    );

    messages.add(userMessage);
    messageController.clear();

    // Create copies of the current files and images
    final currentImages =
        selectedImages.isNotEmpty ? List<File>.from(selectedImages) : null;
    final currentFiles =
        selectedFiles.isNotEmpty ? List<File>.from(selectedFiles) : null;

    // Clear selected files and images for the next message
    clearSelectedMedia();

    // Show loading state
    isLoading.value = true;

    try {
      final response = await _geminiService.sendMessage(
        text,
        images: currentImages,
        files: currentFiles,
      );

      final aiMessage = GeminiMessage(
        id: const Uuid().v4(),
        text:
            response['success']
                ? response['message']
                : 'Error: ${response['message']}',
        isUser: false,
        timestamp: Timestamp.now(),
      );

      messages.add(aiMessage);
    } catch (e) {
      final errorMessage = GeminiMessage(
        id: const Uuid().v4(),
        text: 'Sorry, something went wrong. Please try again later.',
        isUser: false,
        timestamp: Timestamp.now(),
      );

      messages.add(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Pick images from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        selectedImages.add(file);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  // Pick files
  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            selectedFiles.add(File(file.path!));
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick files: $e');
    }
  }

  // Clear selected media
  void clearSelectedMedia() {
    selectedImages.clear();
    selectedFiles.clear();
  }

  // Remove a specific image
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  // Remove a specific file
  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    clearSelectedMedia();
    super.onClose();
  }
}
