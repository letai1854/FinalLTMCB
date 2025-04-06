import 'package:flutter/material.dart';
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Widget/ChatContent.dart';
import 'package:finalltmcb/main.dart';  // Import to access globalGroupController

class Listuserchat extends StatefulWidget {
  const Listuserchat({Key? key}) : super(key: key);

  @override
  State<Listuserchat> createState() => _ListuserchatState();
}

class _ListuserchatState extends State<Listuserchat> {
  String? selectedUserId;

  void onUserSelected(String userId) {
    setState(() {
      selectedUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: MessageList(
              onUserSelected: onUserSelected,
              selectedUserId: selectedUserId,
              isDesktopOrTablet: true, // Mark as desktop/tablet view
              groupController: globalGroupController, // Pass the global instance
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
