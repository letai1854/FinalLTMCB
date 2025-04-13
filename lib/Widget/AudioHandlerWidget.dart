import 'dart:io';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Widget/AudioRecorderWidget.dart';
import 'package:finalltmcb/constants/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioHandlerWidget extends StatefulWidget {
  final Function(ChatMessage message) onAudioMessageSent;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingEnd;
  final bool showRecorder; // New parameter to control display

  const AudioHandlerWidget({
    Key? key,
    required this.onAudioMessageSent,
    this.onRecordingStart,
    this.onRecordingEnd,
    this.showRecorder = false, // Default to showing the button
  }) : super(key: key);

  @override
  _AudioHandlerWidgetState createState() => _AudioHandlerWidgetState();
}

class _AudioHandlerWidgetState extends State<AudioHandlerWidget> {
  // Remove _isRecording state
  bool _isSendingAudio = false;

  // Method to handle saved audio
  void _handleAudioSaved(String audioPath) {
    print("🔊 Audio saved to path: $audioPath");

    if (!mounted) return;

    // No need to set _isRecording false here
    setState(() {
      _isSendingAudio = true;
    });
    widget.onRecordingEnd
        ?.call(); // Notify parent recording ended (or sending started)

    // Process audio in a microtask to avoid blocking UI
    Future.microtask(() async {
      try {
        print("🔊 Creating audio message...");

        final String absolutePath;
        if (kIsWeb) {
          // On web, the path might be a blob URL or similar
          absolutePath = audioPath;
        } else {
          // Ensure absolute path on mobile
          final file = File(audioPath);
          absolutePath = file.absolute.path;
          print("🔊 Absolute audio path: $absolutePath");

          // Optional: Check file size or perform optimization here
          if (await file.exists()) {
            final fileSize = await file.length();
            print("🔊 Audio file size: $fileSize bytes");
            if (fileSize > 5 * 1024 * 1024) {
              // > 5MB
              print("🔊 Large audio file detected");
              // Add compression logic if needed
            }
          }
        }

        // Create the new message
        final newMessage = ChatMessage(
          text: '', // Empty text for audio messages
          isMe: true, // Assuming audio is always sent by 'me' in this context
          timestamp: DateTime.now(),
          audio: absolutePath,
          isAudioPath: true, // Indicate this is a file path
        );

        // Pass the message back to the parent widget
        widget.onAudioMessageSent(newMessage);

        if (mounted) {
          setState(() {
            _isSendingAudio = false; // Finished sending/processing
          });
        }
        print("🔊 Audio message created and sent to parent.");
      } catch (e) {
        print("🔊 ERROR creating audio message: $e");
        if (mounted) {
          setState(() {
            _isSendingAudio = false;
          });
          // Optionally notify parent about the error
        }
        _handleAudioCancel(); // Reset state on error
      }
    });
  }

  // Method to handle recording cancellation (called by AudioRecorderWidget)
  void _handleAudioCancel() {
    if (mounted) {
      setState(() {
        _isSendingAudio =
            false; // Ensure sending state is reset if cancel happens during send
      });
      widget.onRecordingEnd?.call(); // Notify parent that the process ended
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the showRecorder parameter passed from the parent
    if (widget.showRecorder) {
      // Show the recorder widget
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: AudioRecorderWidget(
          onAudioSaved: _handleAudioSaved, // Pass the save handler
          onCancel: _handleAudioCancel, // Pass the cancel handler
        ),
      );
    } else if (_isSendingAudio) {
      // Keep the sending indicator logic
      // Show loading indicator while processing
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.messengerBlue),
              SizedBox(height: 8),
              Text(
                "Đang xử lý audio...",
                style: TextStyle(color: AppColors.messengerBlue),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise, show the microphone button
    return IconButton(
      onPressed: widget.onRecordingStart, // Directly call the parent's callback
      icon: const Icon(
        Icons.mic,
        color: AppColors.messengerBlue,
      ),
      tooltip: 'Ghi âm',
    );
  }
} 

///adjoiadfjofdajk
