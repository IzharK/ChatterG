import 'package:flutter/material.dart';

class GroupInfoScreen extends StatelessWidget {
  final String chatId;

  const GroupInfoScreen({required this.chatId, super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch chat room details using chatId (perhaps via a GetX controller)
    // TODO: Display group name, image, list of members
    // TODO: Add functionality (Edit name/image, Add/Remove members) - requires more logic and Firestore rules

    return Scaffold(
      appBar: AppBar(title: const Text('Group Info')),
      body: Center(
        child: Text(
          'Group Details for Chat ID: $chatId\n(Implementation Pending)',
        ),
      ),
    );
  }
}

// Remember to add a route for this in app_router.dart if you use it
// path: 'group-info/:chatId',
// builder: (context, state) => GroupInfoScreen(chatId: state.pathParameters['chatId']!),
