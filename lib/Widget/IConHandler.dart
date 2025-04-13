import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../constants/colors.dart';

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
      icon: const Icon(
        Icons.emoji_emotions,
        color: AppColors.messengerBlue,
        size: 28, // Tăng kích thước icon
      ),
      padding: EdgeInsets.zero, // Giảm padding xung quanh icon
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ), // Giảm kích thước vùng nhấn tối thiểu
      splashRadius: 20, // Giảm bán kính hiệu ứng khi nhấn
      onPressed: () {
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (BuildContext context) {
            return Positioned(
              child: Stack(
                children: [
                  Positioned(
                    right: 10,
                    bottom: 50,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dialogTheme: DialogTheme(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          content: SizedBox(
                            width: 300,
                            height: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
