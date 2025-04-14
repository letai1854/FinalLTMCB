import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../constants/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class Iconhandler extends StatefulWidget {
  final Function(String)? onEmojiSelected;
  final BuildContext? parentContext;
  
  const Iconhandler({
    super.key, 
    this.onEmojiSelected,
    this.parentContext,
  });

  @override
  State<Iconhandler> createState() => _IconhandlerState();
}

class _IconhandlerState extends State<Iconhandler> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.emoji_emotions,
        color: AppColors.messengerBlue,
        size: 28,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      splashRadius: 20,
      onPressed: () {
        // Keep a reference to the original focus state before showing dialog
        final hasFocus = FocusScope.of(context).hasFocus;
        
        showDialog(
          context: context,
          barrierDismissible: true, // Allow clicking outside to dismiss
          barrierColor: Colors.transparent,
          builder: (BuildContext dialogContext) {
            return Dialog(
              insetPadding: const EdgeInsets.only(
                left: 10, right: 10, top: 100, bottom: 10),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    if (widget.onEmojiSelected != null) {
                      widget.onEmojiSelected!(emoji.emoji);
                    }
                    Navigator.pop(dialogContext);
                  },
                  config: Config(
                    columns: 7,
                    emojiSizeMax: 32.0,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    initCategory: Category.SMILEYS,
                    bgColor: const Color(0xFFF2F2F2),
                    indicatorColor: AppColors.messengerBlue,
                    iconColor: AppColors.lightGrey,
                    iconColorSelected: AppColors.messengerBlue,
                    backspaceColor: AppColors.messengerBlue,
                    skinToneDialogBgColor: Colors.white,
                    skinToneIndicatorColor: AppColors.lightGrey,
                    enableSkinTones: true,
                    recentTabBehavior: RecentTabBehavior.RECENT,
                    recentsLimit: 28,
                    noRecents: const Text(
                      'Không có emoji gần đây',
                      style: TextStyle(fontSize: 16, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                    loadingIndicator: const CircularProgressIndicator(),
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: const CategoryIcons(),
                    buttonMode: ButtonMode.MATERIAL,
                    checkPlatformCompatibility: false,
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
