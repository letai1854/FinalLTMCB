import 'package:finalltmcb/Widget/Footer.dart';
import 'package:finalltmcb/Widget/Navbar.dart';
import 'package:finalltmcb/Widget/SignForm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SignupTablet extends StatelessWidget {
  const SignupTablet({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.1; // 10% padding on each side
    final formWidth = 400.0; // Fixed form width

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: Navbar(),
          actions: [
            Builder(
              builder: (context) => Container(
                margin: EdgeInsets.only(right: 10),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 234, 29, 7),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Center(
                  child: Container(
                    width: formWidth,
                    constraints: BoxConstraints(
                      maxWidth: screenWidth - (horizontalPadding * 2),
                    ),
                    child: const SignForm(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (kIsWeb) const Footer(),
            ],
          ),
        ),
      ),
    );
  }
}
