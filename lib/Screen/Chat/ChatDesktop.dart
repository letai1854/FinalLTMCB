import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/Widget/ChatContent.dart';
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Widget/NavbarAdmin.dart';
import 'package:flutter/material.dart';

class ChatDesktop extends StatefulWidget {
  const ChatDesktop({Key? key}) : super(key: key);

  @override
  State<ChatDesktop> createState() => _ChatDesktopState();
}

class _ChatDesktopState extends State<ChatDesktop> {
  // State to hold the currently selected user
  String? selectedUserId;

  // Callback to handle user selection
  void onUserSelected(String userId) {
    setState(() {
      selectedUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = UserProvider();
    final isAdmin = userProvider.currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const NavbarAdmin(),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: MessageList(
              onUserSelected: onUserSelected,
              selectedUserId: selectedUserId,
              isDesktopOrTablet: true, // Mark as desktop view
            ),
          ),
          Expanded(
            flex: 5,
            child: selectedUserId != null
                ? ChatContent(userId: selectedUserId!)
                : const Center(
                    child: Text('Select a conversation to start chatting')),
          ),
        ],
      ),
    );
  }
}
