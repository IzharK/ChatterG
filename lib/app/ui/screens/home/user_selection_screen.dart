import 'dart:developer';

import 'package:chatter_jee/app/controllers/user_selection_controller.dart';
import 'package:chatter_jee/app/theme/app_theme.dart';
import 'package:chatter_jee/app/ui/widgets/user_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class UserSelectionScreen extends StatelessWidget {
  final controller = Get.put(UserSelectionController());

  UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.only(right: 5),
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
            tooltip: 'Back',
            color: AppColors.textWhite,
            onPressed: () => context.pop(),
          ),
        ),
        title: Obx(
          () => Text(
            controller.selectedUsers.isEmpty
                ? 'Select User'
                : controller.selectedUsers.length == 1
                ? 'Start Chat'
                : 'Create Group',
          ),
        ),
        actions: [
          Obx(
            () =>
                controller.selectedUsers.isNotEmpty
                    ? TextButton(
                      onPressed:
                          controller.isCreatingChat.value
                              ? null
                              : () {
                                controller.createChat(context);
                              },
                      style: TextButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      child:
                          controller.isCreatingChat.value
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text("CREATE", style: TextStyle()),
                    )
                    : Container(color: Colors.green),
          ),
        ],
      ),
      body: Column(
        children: [
          // _buildFloatingAppBar(context),
          Obx(() {
            if (controller.selectedUsers.length > 1) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: controller.groupNameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Enter a name for the group',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.allUsers.isEmpty) {
                return const Center(child: Text('No other users found.'));
              }
              return ListView.builder(
                itemCount: controller.allUsers.length,
                itemBuilder: (context, index) {
                  final user = controller.allUsers[index];
                  return Obx(
                    () => UserListTile(
                      user: user,
                      isSelected: controller.selectedUsers.contains(user),
                      onTap: () {
                        controller.toggleUserSelection(user);
                        log(
                          'selectedUsers length: ${controller.selectedUsers.length}',
                        );
                        controller.update();
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
