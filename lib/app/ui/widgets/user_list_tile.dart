import 'package:chatter_jee/app/data/models/user_model.dart';
import 'package:flutter/material.dart';

class UserListTile extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const UserListTile({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        // Placeholder - replace with user.photoUrl if available
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(user.displayName ?? user.email), // Use display name or email
      subtitle: Text(user.email),
      trailing:
          isSelected
              ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: onTap,
    );
  }
}
