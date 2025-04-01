import 'package:finalltmcb/Widget/Footer.dart';
import 'package:finalltmcb/Widget/LoginForm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// ...existing imports...

class LoginMobile extends StatefulWidget {
  const LoginMobile({super.key});

  @override
  State<LoginMobile> createState() => _LoginMobileState();
}

class _LoginMobileState extends State<LoginMobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient covering entire screen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 234, 29, 7),
                  Color.fromARGB(255, 255, 85, 0),
                ],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Logo section with white background
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            '/logoS.jpg',
                            height: 60,
                            width: 60,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Shopii',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 85, 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Login form section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 30.0),
                  child: Container(
                    color: Colors.white
                        .withOpacity(0.9), // Changed from decoration to color
                    child: const LoginForm(),
                  ),
                ),
                if (kIsWeb) const Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
