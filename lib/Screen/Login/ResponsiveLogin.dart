import 'package:finalltmcb/Responsive/ResponsiveLayout.dart';
import 'package:finalltmcb/Screen/Login/LoginDesktop.dart';
import 'package:finalltmcb/Screen/Login/LoginMobile.dart';
import 'package:finalltmcb/Screen/Login/LoginTablet.dart';
import 'package:flutter/material.dart';

class ResponsiveLogin extends StatelessWidget {
  const ResponsiveLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileScaffold: const LoginMobile(),
        tableScaffold: const LoginTablet(),
        destopScaffold: const LoginDesktop(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey.shade800,
        mini: true,
        child: const Icon(Icons.bug_report, size: 20),
        onPressed: () {
          Navigator.pushNamed(context, '/debug');
        },
        tooltip: 'UDP Debug Console',
      ),
    );
  }
}
