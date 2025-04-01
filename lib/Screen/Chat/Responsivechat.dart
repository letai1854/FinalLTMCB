import 'package:finalltmcb/Responsive/ResponsiveLayout.dart';
import 'package:finalltmcb/Screen/Chat/ChatDesktop.dart';
import 'package:finalltmcb/Screen/Chat/ChatTablet.dart';
import 'package:finalltmcb/Screen/Chat/listUserMobile.dart';
import 'package:flutter/material.dart';

class Responsivechat extends StatelessWidget {
  const Responsivechat({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const ListUserMobile(),
      tableScaffold: const ChatTablet(),
      destopScaffold: const ChatDesktop(),
    );
  }
}
