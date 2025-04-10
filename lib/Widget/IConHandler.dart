import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class Iconhandler extends StatefulWidget {
  final Function(String)? onEmojiSelected;
  
  const Iconhandler({
    super.key, 
    this.onEmojiSelected
  });

  @override
  State<Iconhandler> createState() => _IconhandlerState();
}

class _IconhandlerState extends State<Iconhandler> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.emoji_emotions, color: Colors.red),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 300,
                height: 400,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    if (widget.onEmojiSelected != null) {
                      widget.onEmojiSelected!(emoji.emoji);
                    }
                    Navigator.pop(context);
                  },
                  config: Config(
                    columns: 7,
                    emojiSizeMax: 32.0,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    initCategory: Category.SMILEYS,
                    bgColor: const Color(0xFFF2F2F2),
                    indicatorColor: Colors.red,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.red,
                    backspaceColor: Colors.red,
                    skinToneDialogBgColor: Colors.white,
                    skinToneIndicatorColor: Colors.grey,
                    enableSkinTones: true,
                    recentTabBehavior: RecentTabBehavior.RECENT,
                    recentsLimit: 28,
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(fontSize: 20, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                    loadingIndicator: const SizedBox.shrink(),
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: const CategoryIcons(),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
