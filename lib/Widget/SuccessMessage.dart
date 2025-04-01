import 'package:flutter/material.dart';

class SuccessMessage {
  static void show(
    BuildContext context, {
    required String title,
    VoidCallback? onDismissed,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: 20, // Add top margin to position at top
          left: MediaQuery.of(context).size.width * 0.3, // Center horizontally
          right: MediaQuery.of(context).size.width * 0.3,
        ),
      ),
    );

    if (onDismissed != null) {
      Future.delayed(duration, onDismissed);
    }
  }
}
