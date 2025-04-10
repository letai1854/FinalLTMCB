import 'package:finalltmcb/Controllers/GroupController.dart';
import 'package:finalltmcb/Controllers/MessageController.dart';
import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/Widget/ChatContent.dart';
import 'package:finalltmcb/Widget/NavbarAdmin.dart';
import 'package:flutter/material.dart';

class ChatMobile extends StatefulWidget {
  final String userId;
  GroupController groupController;
  MessageController messageController; // Access the global instance
  ChatMobile({
    Key? key,
    required this.userId,
    required this.groupController,
    required this.messageController, // Pass the global instance
    // Pass the global instance
  }) : super(key: key);

  @override
  State<ChatMobile> createState() => _ChatMobileState();
}

class _ChatMobileState extends State<ChatMobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const NavbarAdmin(),
      ),
      body: ChatContent(
        userId: widget.userId,
        groupController: widget.groupController,
        messageController: widget.messageController, // Pass the global instance
      ),
    );
  }
}
