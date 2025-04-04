import 'package:finalltmcb/Widget/Footer.dart';
import 'package:finalltmcb/Widget/LoginForm.dart';
import 'package:finalltmcb/Widget/Navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class LoginDesktop extends StatelessWidget {
  const LoginDesktop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Navbar(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 234, 29, 7),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                // image: DecorationImage(
                                //   image: AssetImage('/banner.jpg'),
                                // ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 400,
                                constraints: BoxConstraints(
                                  maxHeight: 400,
                                  minHeight: 350,
                                ),
                                child: LoginForm(),
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
