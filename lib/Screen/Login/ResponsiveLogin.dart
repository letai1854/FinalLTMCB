import 'package:finalltmcb/Responsive/ResponsiveLayout.dart';
import 'package:finalltmcb/Screen/Login/LoginDesktop.dart';
import 'package:finalltmcb/Screen/Login/LoginMobile.dart';
import 'package:finalltmcb/Screen/Login/LoginTablet.dart';
import 'package:flutter/material.dart';

class ResponsiveLogin extends StatelessWidget {
  const ResponsiveLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const LoginMobile(),
      tableScaffold: const LoginTablet(),
      destopScaffold: const LoginDesktop(),
    );
  }
}
