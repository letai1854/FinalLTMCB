import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  const Navbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth < 1100;

    return Container(
      height: 80,
      color: const Color.fromARGB(255, 255, 255, 255),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            margin: EdgeInsets.only(
                right: isTablet ? 200 : 550), // Adjusted margin for tablet
            child: Row(
              children: [
                Image.asset(
                  '/logoS.jpg',
                  height: 60,
                  width: 60,
                ),
                SizedBox(width: 8),
                Text(
                  'Shopii',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 85, 0),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.home,
            size: 30,
            color: const Color.fromARGB(255, 255, 85, 0),
          ),
        ],
      ),
    );
  }
}
