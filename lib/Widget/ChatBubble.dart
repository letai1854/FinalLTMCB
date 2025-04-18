import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Widget/AudioBubble.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:finalltmcb/Widget/VideoBubble.dart';
import '../constants/colors.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(FileMessage)? onFileDownload;
  final bool showSenderName; // Add this

  const ChatBubble({
    Key? key,
    required this.message,
    this.onFileDownload,
    this.showSenderName = true, // Default to true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Always show sender name for any message type if it's not from the current user
            if (showSenderName && !message.isMe && message.name != null && message.name!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                // child: Text(
                //   message.name!,
                //   style: TextStyle(
                //     fontSize: 12.0,
                //     color: Colors.grey.shade600,
                //     fontWeight: FontWeight.bold, // Make the name bold for better visibility
                //   ),
                // ),
              ),

            // Content
            _buildMessageContent(context),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 4.0, left: 4.0),
              child: Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Check if message has a video
    if (message.isVideoMessage) {
      return VideoBubble(
        videoPath: message.video!.localPath,
        isMe: message.isMe,
        isLoading: message.isVideoLoading,
      );
    }

    // Check if message has a file
    if (message.isFileMessage) {
      return FileBubble(
        file: message.file!,
        isMe: message.isMe,
        onTap: () {
          // Use the callback directly instead of trying to find ancestor
          if (onFileDownload != null) {
            onFileDownload!(message.file!);
          } else {
            // Fallback if callback not provided
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot download file right now')),
            );
          }
        },
      );
    }

    // Check if message has audio
    if (message.isAudioMessage) {
      print(
          "Rendering audio message: path=${message.isAudioPath}, length=${message.audio!.length}");
      return AudioBubble(
        audioSource: message.audio!,
        isMe: message.isMe,
        timestamp: message.timestamp,
        isPath: message.isAudioPath,
      );
    }

    // Check if message has image
    if (message.isImageMessage) {
      return GestureDetector(
        onTap: () {
          // Navigate to full screen image view
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: IconThemeData(color: Colors.white),
                  elevation: 0,
                ),
                body: Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.memory(
                      base64Decode(message.image!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
            maxHeight: 250, // Increased max height for better preview
          ),
          decoration: BoxDecoration(
            color: message.isMe ? Colors.red.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Image.memory(
              base64Decode(message.image!),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // Text message
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.5,
      ),
      decoration: BoxDecoration(
        color: message.isMe 
            ? AppColors.messengerBlue
            : AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: Colors.blue.shade800,
          ),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            fontSize: 16.0,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
