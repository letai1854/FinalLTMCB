import 'package:finalltmcb/Widget/Footer.dart';
import 'package:finalltmcb/Widget/Navbar.dart';
import 'package:finalltmcb/Widget/SignForm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class SignUpDesktop extends StatelessWidget {
  const SignUpDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Navbar(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGrey,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 400,
                                constraints: BoxConstraints(
                                  maxHeight: 490, // Increased from 430 to 550
                                  minHeight: 350,
                                  minWidth: 350,
                                ),
                                child: SignForm(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (kIsWeb)
              Column(
                children: [
                  Footer(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
