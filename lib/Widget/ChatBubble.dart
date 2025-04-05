import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Widget/AudioBubble.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:finalltmcb/Widget/VideoBubble.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  // Add a callback for file download handling
  final Function(FileMessage)? onFileDownload;

  const ChatBubble({
    Key? key,
    required this.message,
    this.onFileDownload,
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
    // Check if message has a video (using videoBytes)
    if (message.videoBytes != null) {
      return VideoBubble(
        videoPath: message.video!, // Still use videoPath for now
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
            maxWidth: MediaQuery.of(context).size.width * 0.7,
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
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: message.isMe ? Colors.red.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
      child: Text(
        message.text,
        style: const TextStyle(
          fontSize: 16.0,
        ),
      ),
    );
  }
}
