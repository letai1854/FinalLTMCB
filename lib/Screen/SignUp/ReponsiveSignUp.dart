import 'package:finalltmcb/Responsive/ResponsiveLayout.dart';
import 'package:finalltmcb/Screen/SignUp/SignUpDesktop.dart';
import 'package:finalltmcb/Screen/SignUp/SignupMobile.dart';
import 'package:finalltmcb/Screen/SignUp/SignupTablet.dart';
import 'package:flutter/material.dart';

class ReponsiveSignUp extends StatelessWidget {
  const ReponsiveSignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const SignupMobile(),
      tableScaffold: const SignupTablet(),
      destopScaffold: const SignUpDesktop(),
    );
  }
}
