import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Widget/ChatContent.dart';
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Widget/NavbarAdmin.dart';
import 'package:finalltmcb/main.dart';  // Import to access globalGroupController

class ChatTablet extends StatefulWidget {
  const ChatTablet({Key? key}) : super(key: key);

  @override
  State<ChatTablet> createState() => _ChatTabletState();
}

class _ChatTabletState extends State<ChatTablet> {
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const NavbarAdmin(),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                  border: Border(
                      right:
                          BorderSide(width: 1, color: Colors.grey.shade300))),
              child: MessageList(
                onUserSelected: onUserSelected,
                selectedUserId: selectedUserId,
                isDesktopOrTablet: true, // Mark as tablet view
                groupController: globalGroupController, // Pass the global instance
              ),
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
