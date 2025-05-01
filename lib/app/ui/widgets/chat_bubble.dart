import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:chatter_jee/app/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final String messageText;
  final Timestamp timestamp;
  final bool isMe;
  final bool hasError;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? attachmentName;

  const ChatBubble({
    super.key,
    required this.messageText,
    required this.timestamp,
    required this.isMe,
    this.hasError = false,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe ? AppColors.primary : AppColors.incomingBubble;
    final textColor =
        hasError
            ? AppColors.errorRed
            : (isMe ? AppColors.textBlack : AppColors.textWhite);
    final timeColor =
        hasError
            ? AppColors.errorRed.withValues(alpha: 0.7)
            : (isMe
                ? AppColors.textBlack.withValues(alpha: 0.7)
                : AppColors.textGrey);
    final errorIndicatorColor = Colors.orangeAccent;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    log('attachmentUrl: $attachmentUrl');
    bool hasText = messageText.isNotEmpty;
    bool hasAttachment = attachmentUrl != null && attachmentType != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Attachment Display ---
            if (hasAttachment) _buildAttachment(context, textColor),

            // --- Message Text ---
            if (hasText)
              Padding(
                padding: EdgeInsets.only(top: hasAttachment ? 6.0 : 0),
                child: Text(
                  messageText,
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
              ),

            // --- Timestamp and Error Indicator ---
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.error_outline,
                        size: 14,
                        color: errorIndicatorColor,
                      ),
                    ),
                  Text(
                    Helpers.formatTimestamp(timestamp),
                    style: TextStyle(color: timeColor, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for building attachment view
  Widget _buildAttachment(BuildContext context, Color textColor) {
    if (attachmentType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => _viewImage(context, attachmentUrl!),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: CachedNetworkImage(
              imageUrl: attachmentUrl!,
              placeholder:
                  (context, url) => Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else if (attachmentType == 'file') {
      return InkWell(
        onTap: () => _openFile(attachmentUrl!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(isMe ? 0.1 : 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 28,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  attachmentName ?? 'File',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _viewImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.cancel_outlined,
                    color: Theme.of(context).secondaryHeaderColor,
                    size: 30,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _openFile(String fileUrl) async {
    final Uri url = Uri.parse(fileUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
