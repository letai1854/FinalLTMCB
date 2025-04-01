import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileScaffold;
  final Widget tableScaffold;
  final Widget destopScaffold;
  const ResponsiveLayout(
      {super.key,
      required this.mobileScaffold,
      required this.tableScaffold,
      required this.destopScaffold});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobileScaffold;
        } else if (constraints.maxWidth < 1100) {
          return tableScaffold;
        } else {
          return destopScaffold;
        }
      },
    );
  }
}
