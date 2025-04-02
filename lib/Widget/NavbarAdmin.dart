import 'package:flutter/material.dart';

class NavbarAdmin extends StatelessWidget {
  const NavbarAdmin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 600;
      bool isTablet = constraints.maxWidth < 1100 && !isMobile;

      return Container(
        height: 80,
        color: const Color.fromARGB(255, 255, 255, 255),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.spaceAround,
          children: [
            if (isMobile)
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color.fromARGB(255, 255, 85, 0),
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),

            Container(
              margin: isMobile
                  ? EdgeInsets.zero
                  : EdgeInsets.only(right: isTablet ? 200 : 550),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: Row(
                    children: [
                      // Image.asset(
                      //   '/logoS.jpg',
                      //   height: 60,
                      //   width: 60,
                      // ),
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

            // Add empty SizedBox to balance the layout on mobile
            if (isMobile) SizedBox(width: 48), // Width matches the back button

            if (!isMobile) const SizedBox(width: 8),
          ],
        ),
      );
    });
  }
}
