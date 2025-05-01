import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class GeminiModel {
  final String id;
  final String name;
  final String displayName;
  final bool supportsImages;
  final bool supportsFiles;

  GeminiModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.supportsImages = false,
    this.supportsFiles = false,
  });
}

class GeminiService extends GetxService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _apiKeyStorageKey = 'gemini_api_key';
  final String _selectedModelKey = 'selected_gemini_model';
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  // Observable values for token usage and model selection
  final RxInt usedTokens = 0.obs;
  final RxInt totalTokens = 1048576.obs;
  final Rx<GeminiModel> selectedModel =
      GeminiModel(
        id: 'gemini-2.5-pro-exp-03-25',
        name: 'gemini-2.5-pro',
        displayName: 'Gemini 2.5 Pro',
        supportsImages: true,
        supportsFiles: true,
      ).obs;

  // List of available models
  final RxList<GeminiModel> availableModels =
      <GeminiModel>[
        GeminiModel(
          id: 'gemini-2.5-pro-exp-03-25',
          name: 'gemini-2.5-pro',
          displayName: 'Gemini 2.5 Pro',
          supportsImages: true,
          supportsFiles: true,
        ),
        GeminiModel(
          id: 'gemini-pro',
          name: 'gemini-pro',
          displayName: 'Gemini Pro',
          supportsImages: false,
          supportsFiles: false,
        ),
        GeminiModel(
          id: 'gemini-pro-vision',
          name: 'gemini-pro-vision',
          displayName: 'Gemini Pro Vision',
          supportsImages: true,
          supportsFiles: false,
        ),
      ].obs;

  // Store API key securely
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  // Retrieve API key
  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }

  // Delete API key
  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  // Check if API key exists
  Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  // Get available models from API
  Future<List<GeminiModel>> fetchAvailableModels() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return availableModels;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );
      log('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final models = responseData['models'] as List;

        // Filter for Gemini models only
        final geminiModels =
            models
                .where((model) => model['name'].toString().contains('gemini'))
                .map((model) {
                  final modelId = model['name'].toString().split('/').last;
                  final displayName = model['displayName'] ?? modelId;
                  final supportsImages = modelId.contains('vision');
                  final supportsFiles = modelId.contains('2.5');

                  return GeminiModel(
                    id: modelId,
                    name: modelId,
                    displayName: displayName,
                    supportsImages: supportsImages,
                    supportsFiles: supportsFiles,
                  );
                })
                .toList();

        if (geminiModels.isNotEmpty) {
          availableModels.value = geminiModels;
        }
      }
    } catch (e) {
      // If API call fails, use the default models
    }

    return availableModels;
  }

  // Save selected model
  Future<void> saveSelectedModel(GeminiModel model) async {
    await _secureStorage.write(
      key: _selectedModelKey,
      value: jsonEncode({
        'id': model.id,
        'name': model.name,
        'displayName': model.displayName,
        'supportsImages': model.supportsImages,
        'supportsFiles': model.supportsFiles,
      }),
    );
    selectedModel.value = model;
  }

  // Load selected model
  Future<void> loadSelectedModel() async {
    final modelJson = await _secureStorage.read(key: _selectedModelKey);
    if (modelJson != null && modelJson.isNotEmpty) {
      try {
        final modelData = jsonDecode(modelJson);
        selectedModel.value = GeminiModel(
          id: modelData['id'],
          name: modelData['name'],
          displayName: modelData['displayName'],
          supportsImages: modelData['supportsImages'] ?? false,
          supportsFiles: modelData['supportsFiles'] ?? false,
        );
      } catch (e) {
        // If loading fails, keep the default model
      }
    }
  }

  // Send message to Gemini API
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    List<File>? images,
    List<File>? files,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return {
        'success': false,
        'message':
            'API key not found. Please add your Gemini API key in settings.',
      };
    }

    try {
      final model = selectedModel.value;
      final modelEndpoint =
          '$_baseUrl/models/${model.id}:generateContent?key=$apiKey';

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'contents': [
          {'parts': []},
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
      };

      // Add text message
      if (message.isNotEmpty) {
        requestBody['contents'][0]['parts'].add({'text': message});
      }

      // Add images if supported and provided
      if (model.supportsImages && images != null && images.isNotEmpty) {
        for (final image in images) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

          requestBody['contents'][0]['parts'].add({
            'inline_data': {'mime_type': mimeType, 'data': base64Image},
          });
        }
      }

      // Add files if supported and provided
      if (model.supportsFiles && files != null && files.isNotEmpty) {
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final base64File = base64Encode(bytes);
          final mimeType =
              lookupMimeType(file.path) ?? 'application/octet-stream';

          requestBody['contents'][0]['parts'].add({
            'file_data': {
              'mime_type': mimeType,
              'file_uri': 'data:$mimeType;base64,$base64File',
            },
          });
        }
      }

      final response = await http.post(
        Uri.parse(modelEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      // Update token usage if available in response
      if (responseData.containsKey('usageMetadata')) {
        final totalTokensUsed =
            responseData['usageMetadata']['totalTokenCount'] ?? 0;
        usedTokens.value = totalTokensUsed;
      }

      if (response.statusCode == 200) {
        final text =
            responseData['candidates'][0]['content']['parts'][0]['text'];
        return {'success': true, 'message': text};
      } else {
        return {
          'success': false,
          'message':
              'Error: ${responseData['error']['message'] ?? "Unknown error"}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Count tokens for a message
  Future<int?> countTokens(String text) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    try {
      final model = selectedModel.value;
      final response = await http.post(
        Uri.parse('$_baseUrl/models/${model.name}:countTokens?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': text},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['totalTokens'];
      }
    } catch (e) {
      // Ignore token counting errors
    }

    return null;
  }

  // Update token usage
  Future<void> updateTokenUsage() async {
    try {
      final tokenCount = await countTokens("Sample text");
      if (tokenCount != null) {
        usedTokens.value = tokenCount;
      }
    } catch (e) {
      // Ignore token counting errors
    }
  }
}
