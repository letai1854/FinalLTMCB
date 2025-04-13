import 'package:flutter/material.dart';
import '../constants/colors.dart';

class Navbar extends StatelessWidget {
  const Navbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth < 1100;

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightGrey,
            width: 0.3
          )
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            margin: EdgeInsets.only(
                right: isTablet ? 200 : 550), // Adjusted margin for tablet
            child: Row(
              children: [
                Image.asset(
                  'assets/appLogo.png',
                  height: 60,
                  width: 60,
                ),
                SizedBox(width: 8),
                Text(
                  'facebug',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.messengerBlue,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.home,
            size: 30,
            color: AppColors.messengerBlue,
          ),
        ],
      ),
    );
  }
}
