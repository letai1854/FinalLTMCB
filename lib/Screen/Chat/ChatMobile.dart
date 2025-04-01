import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/Widget/ChatContent.dart';
import 'package:finalltmcb/Widget/NavbarAdmin.dart';
import 'package:flutter/material.dart';

class ChatMobile extends StatefulWidget {
  final String userId;

  const ChatMobile({
    Key? key,
    required this.userId,
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
      body: ChatContent(userId: widget.userId),
    );
  }
}
