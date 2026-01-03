import 'package:chatter_jee/app/controllers/gemini_controller.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart'; // TODO: Uncomment when file upload is needed
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class GeminiChatScreen extends StatelessWidget {
  final controller = Get.put(GeminiController());
  final modelController = TextEditingController();

  GeminiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text('Chat with Gemini'),
        actions: [
          // Model selector dropdown
          Obx(() {
            return DropdownMenu(
              onSelected: (value) => controller.selectModel(value!),
              controller: modelController,
              hintText: 'Select a model',
              textStyle: const TextStyle(color: AppColors.textWhite),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.background,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.background),
                surfaceTintColor: WidgetStateProperty.all(AppColors.background),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
                alignment: AlignmentDirectional.center,
              ),
              dropdownMenuEntries:
                  controller.availableModels.map((model) {
                    return DropdownMenuEntry(
                      value: model,
                      label: model.displayName,
                      labelWidget: Text(
                        model.displayName,
                        style: TextStyle(color: AppColors.textWhite),
                      ),
                    );
                  }).toList(),
            );
          }),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Token Usage',
            onPressed: () => _showTokenUsageDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Token usage indicator
          Obx(() {
            final used = controller.usedTokens.value;
            final total = controller.totalTokens.value;
            final percentage = total > 0 ? (used / total) : 0.0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Token Usage: ${used.toString()} / ${total.toString()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Messages list
          Expanded(
            child: Obx(() {
              if (!controller.hasApiKey.value &&
                  controller.messages.length <= 1) {
                return _buildApiKeyPrompt();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  return _buildMessageBubble(message, context);
                },
              );
            }),
          ),

          // TODO: Uncomment when file upload is needed
          // // Selected media preview
          // Obx(() {
          //   final hasMedia =
          //       controller.selectedImages.isNotEmpty ||
          //       controller.selectedFiles.isNotEmpty;
          //
          //   if (!hasMedia) return const SizedBox.shrink();
          //
          //   return Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     color: AppColors.surface,
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         // Images preview
          //         if (controller.selectedImages.isNotEmpty) ...[
          //           const Text(
          //             'Selected Images:',
          //             style: TextStyle(color: AppColors.textGrey),
          //           ),
          //           const SizedBox(height: 8),
          //           SizedBox(
          //             height: 100,
          //             child: ListView.builder(
          //               scrollDirection: Axis.horizontal,
          //               itemCount: controller.selectedImages.length,
          //               itemBuilder: (context, index) {
          //                 final image = controller.selectedImages[index];
          //                 return Stack(
          //                   children: [
          //                     Container(
          //                       margin: const EdgeInsets.only(right: 8),
          //                       width: 100,
          //                       height: 100,
          //                       decoration: BoxDecoration(
          //                         borderRadius: BorderRadius.circular(8),
          //                         image: DecorationImage(
          //                           image: FileImage(image),
          //                           fit: BoxFit.cover,
          //                         ),
          //                       ),
          //                     ),
          //                     Positioned(
          //                       top: 0,
          //                       right: 8,
          //                       child: GestureDetector(
          //                         onTap: () => controller.removeImage(index),
          //                         child: Container(
          //                           padding: const EdgeInsets.all(4),
          //                           decoration: const BoxDecoration(
          //                             color: Colors.black54,
          //                             shape: BoxShape.circle,
          //                           ),
          //                           child: const Icon(
          //                             Icons.close,
          //                             size: 16,
          //                             color: Colors.white,
          //                           ),
          //                         ),
          //                       ),
          //                     ),
          //                   ],
          //                 );
          //               },
          //             ),
          //           ),
          //         ],
          //
          //         // Files preview
          //         if (controller.selectedFiles.isNotEmpty) ...[
          //           const SizedBox(height: 8),
          //           const Text(
          //             'Selected Files:',
          //             style: TextStyle(color: AppColors.textGrey),
          //           ),
          //           const SizedBox(height: 8),
          //           ListView.builder(
          //             shrinkWrap: true,
          //             physics: const NeverScrollableScrollPhysics(),
          //             itemCount: controller.selectedFiles.length,
          //             itemBuilder: (context, index) {
          //               final file = controller.selectedFiles[index];
          //               return Container(
          //                 margin: const EdgeInsets.only(bottom: 8),
          //                 padding: const EdgeInsets.symmetric(
          //                   horizontal: 12,
          //                   vertical: 8,
          //                 ),
          //                 decoration: BoxDecoration(
          //                   color: AppColors.background,
          //                   borderRadius: BorderRadius.circular(8),
          //                 ),
          //                 child: Row(
          //                   children: [
          //                     const Icon(
          //                       Icons.insert_drive_file,
          //                       color: AppColors.primary,
          //                     ),
          //                     const SizedBox(width: 8),
          //                     Expanded(
          //                       child: Text(
          //                         file.path.split('/').last,
          //                         style: const TextStyle(
          //                           color: AppColors.textWhite,
          //                         ),
          //                         overflow: TextOverflow.ellipsis,
          //                       ),
          //                     ),
          //                     IconButton(
          //                       icon: const Icon(
          //                         Icons.close,
          //                         color: AppColors.textGrey,
          //                       ),
          //                       onPressed: () => controller.removeFile(index),
          //                       iconSize: 16,
          //                       padding: EdgeInsets.zero,
          //                       constraints: const BoxConstraints(),
          //                     ),
          //                   ],
          //                 ),
          //               );
          //             },
          //           ),
          //         ],
          //
          //         // Clear all button
          //         Align(
          //           alignment: Alignment.centerRight,
          //           child: TextButton(
          //             onPressed: () => controller.clearSelectedMedia(),
          //             child: const Text('Clear All'),
          //           ),
          //         ),
          //       ],
          //     ),
          //   );
          // }),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textWhite),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) {
                          controller.sendMessage(text);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () =>
                          controller.isLoading.value
                              ? const CircularProgressIndicator()
                              : IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  controller.sendMessage(
                                    controller.messageController.text,
                                  );
                                },
                              ),
                    ),
                  ],
                ),

                // TODO: Uncomment when file upload is needed
                // // Media attachment buttons
                // Padding(
                //   padding: const EdgeInsets.only(top: 8),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //     children: [
                //       Obx(
                //         () => IconButton(
                //           icon: const Icon(
                //             Icons.camera_alt,
                //             color: AppColors.primary,
                //           ),
                //           onPressed:
                //               controller.selectedModel.value.supportsImages
                //                   ? () =>
                //                       controller.pickImage(ImageSource.camera)
                //                   : null,
                //           tooltip: 'Take Photo',
                //           color:
                //               controller.selectedModel.value.supportsImages
                //                   ? AppColors.primary
                //                   : AppColors.textGrey,
                //         ),
                //       ),
                //       Obx(
                //         () => IconButton(
                //           icon: const Icon(
                //             Icons.photo,
                //             color: AppColors.primary,
                //           ),
                //           onPressed:
                //               controller.selectedModel.value.supportsImages
                //                   ? () =>
                //                       controller.pickImage(ImageSource.gallery)
                //                   : null,
                //           tooltip: 'Choose from Gallery',
                //           color:
                //               controller.selectedModel.value.supportsImages
                //                   ? AppColors.primary
                //                   : AppColors.textGrey,
                //         ),
                //       ),
                //       Obx(
                //         () => IconButton(
                //           icon: const Icon(
                //             Icons.attach_file,
                //             color: AppColors.primary,
                //           ),
                //           onPressed:
                //               controller.selectedModel.value.supportsFiles
                //                   ? () => controller.pickFiles()
                //                   : null,
                //           tooltip: 'Attach Files',
                //           color:
                //               controller.selectedModel.value.supportsFiles
                //                   ? AppColors.primary
                //                   : AppColors.textGrey,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(GeminiMessage message, BuildContext context) {
    final isUser = message.isUser;
    final time = DateFormat.Hm().format(message.timestamp.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: SvgPicture.asset(
                'assets/images/google-gemini-icon.svg',
                height: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildApiKeyPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Gemini API Key Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To chat with Gemini, you need to add your API key in the settings.',
              style: TextStyle(fontSize: 16, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.toNamed('/settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Go to Settings'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _launchGeminiApiKeyUrl(),
              child: const Text(
                'Get a Gemini API Key',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTokenUsageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Token Usage Information'),
            content: Obx(() {
              final used = controller.usedTokens.value;
              final total = controller.totalTokens.value;
              final percentage = total > 0 ? (used / total) * 100 : 0.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Used: ${used.toString()} tokens'),
                  const SizedBox(height: 8),
                  Text('Total: ${total.toString()} tokens'),
                  const SizedBox(height: 8),
                  Text('Percentage: ${percentage.toStringAsFixed(1)}%'),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: Token usage resets according to your Gemini API quota.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              );
            }),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _launchGeminiApiKeyUrl() async {
    const url = 'https://aistudio.google.com/app/apikey';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
