import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Widget/NavbarAdmin.dart';
import 'package:finalltmcb/Screen/Chat/ChatMobile.dart';
import 'package:flutter/material.dart';
import 'package:finalltmcb/main.dart'; // Import to access globalGroupController

class ListUserMobile extends StatefulWidget {
  const ListUserMobile({Key? key}) : super(key: key);

  @override
  State<ListUserMobile> createState() => _ListUserMobileState();
}

class _ListUserMobileState extends State<ListUserMobile> {
  // Callback to handle user selection
  void onUserSelected(String userId) {
    // Navigate to the chat screen with the selected user
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMobile(
            userId: userId,
            groupController: globalGroupController), // Pass the global instance
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const NavbarAdmin(),
      ),
      body: MessageList(
        onUserSelected: onUserSelected,
        isDesktopOrTablet: false, // Explicitly mark as mobile view
        groupController: globalGroupController, // Pass the global instance
      ),
    );
  }
}
