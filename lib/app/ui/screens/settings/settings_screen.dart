import 'package:chatter_jee/app/controllers/auth_controller.dart';
import 'package:chatter_jee/app/data/providers/gemini_service.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _geminiService = Get.find<GeminiService>();
  final _authController = Get.find<AuthController>();
  final _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;
  bool _isLoading = true;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    setState(() => _isLoading = true);
    final apiKey = await _geminiService.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKeyController.text = apiKey;
      setState(() => _hasApiKey = true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      Get.snackbar(
        'Error',
        'API key cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorRed.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    await _geminiService.saveApiKey(apiKey);
    setState(() {
      _isLoading = false;
      _hasApiKey = true;
      _isApiKeyVisible = false;
    });

    Get.snackbar(
      'Success',
      'Gemini API key saved successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  Future<void> _deleteApiKey() async {
    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete API Key'),
            content: const Text(
              'Are you sure you want to delete your Gemini API key?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      setState(() => _isLoading = true);
      await _geminiService.deleteApiKey();
      _apiKeyController.clear();
      setState(() {
        _isLoading = false;
        _hasApiKey = false;
      });

      Get.snackbar(
        'Success',
        'Gemini API key deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _launchGeminiApiKeyUrl() async {
    const url = 'https://aistudio.google.com/app/apikey';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar(
        'Error',
        'Could not open URL',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorRed.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Settings'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Account section
                  _buildSectionHeader('Account'),
                  _buildAccountTile(),
                  const SizedBox(height: 24),

                  // Gemini API section
                  _buildSectionHeader('Gemini AI Integration'),
                  _buildGeminiApiKeyTile(),
                  if (!_hasApiKey) _buildGetApiKeyButton(),
                  const SizedBox(height: 24),

                  // App info section
                  _buildSectionHeader('App Information'),
                  _buildInfoTile('Version', '1.0.0'),
                  _buildInfoTile('Build', '1'),
                ],
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAccountTile() {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(_authController.firestoreUser.value?.displayName ?? 'User'),
        subtitle: Text(_authController.firestoreUser.value?.email ?? ''),
        trailing: IconButton(
          icon: const Icon(Icons.logout, color: AppColors.errorRed),
          onPressed: () => _authController.signOut(),
        ),
      ),
    );
  }

  Widget _buildGeminiApiKeyTile() {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Gemini API Key',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_hasApiKey)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.errorRed),
                    onPressed: _deleteApiKey,
                    tooltip: 'Delete API Key',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your API key is encrypted and stored securely on your device.',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'Enter your Gemini API key',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isApiKeyVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textGrey,
                      ),
                      onPressed: () {
                        setState(() => _isApiKeyVisible = !_isApiKeyVisible);
                      },
                    ),
                  ],
                ),
              ),
              obscureText: !_isApiKeyVisible,
              style: const TextStyle(color: AppColors.textWhite),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_hasApiKey ? 'Update API Key' : 'Save API Key'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetApiKeyButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton.icon(
        onPressed: _launchGeminiApiKeyUrl,
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Get a Gemini API Key'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(color: AppColors.textGrey),
        ),
      ),
    );
  }
}
