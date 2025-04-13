import 'package:flutter/material.dart';
import '../constants/colors.dart';

typedef AttachmentCallback = Future<void> Function();

class AttachmentMenuWidget extends StatefulWidget {
  final AttachmentCallback onFileSelected;
  final AttachmentCallback onVideoSelected;
  final Color iconColor;

  const AttachmentMenuWidget({
    Key? key,
    required this.onFileSelected,
    required this.onVideoSelected,
    this.iconColor = AppColors.messengerBlue,
  }) : super(key: key);

  @override
  State<AttachmentMenuWidget> createState() => _AttachmentMenuWidgetState();
}

class _AttachmentMenuWidgetState extends State<AttachmentMenuWidget> {
  bool _isMenuVisible = false;
  final GlobalKey _addButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  void _toggleMenu() {
    print("Toggle menu called, current state: $_isMenuVisible");

    if (_isMenuVisible) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _closeMenu() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isMenuVisible = false);
    }
  }

  void _openMenu() {
    // Find the button position using the GlobalKey
    final RenderBox? buttonBox =
        _addButtonKey.currentContext?.findRenderObject() as RenderBox?;

    if (buttonBox == null) {
      print("Cannot find add button position");
      return;
    }

    // Calculate the position of the button in the global coordinate system
    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final buttonSize = buttonBox.size;

    // Calculate the menu position to appear just above the button
    final double menuLeft = buttonPosition.dx;
    final double menuTop = buttonPosition.dy - 115; // Position just above the button

    print(
        "Button position: $buttonPosition, Menu position: ($menuLeft, $menuTop)");

    // Create and position the overlay
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: menuLeft,
        top: menuTop,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: Container(
            width: 50, // Fixed width to ensure proper sizing
            padding: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // File option
                InkWell(
                  onTap: () {
                    _closeMenu(); // Close menu before processing
                    // Use Future.microtask to prevent UI interruption
                    Future.microtask(() => widget.onFileSelected());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.insert_drive_file,
                      color: widget.iconColor,
                      size: 24,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1),
                // Video option
                InkWell(
                  onTap: () {
                    _closeMenu(); // Close menu before processing
                    // Use Future.microtask to prevent UI interruption
                    Future.microtask(() => widget.onVideoSelected());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.videocam,
                      color: widget.iconColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Use a try-catch to prevent app crashes if overlay insertion fails
    try {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isMenuVisible = true);
    } catch (e) {
      print("Error showing menu: $e");
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _addButtonKey,
      onPressed: () {
        print("Add button pressed");
        _toggleMenu();
      },
      icon: Icon(
        Icons.add,
        color: widget.iconColor,
      ),
      tooltip: 'Add attachment',
    );
  }
}
