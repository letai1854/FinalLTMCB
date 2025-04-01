import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: message.image != null
              ? const EdgeInsets.all(2.0) // Less padding for images
              : const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isMe ? Colors.red.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.image != null)
                _buildImageContent(context)
              else
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 16.0),
                ),
              // Only show timestamp for text messages
              if (message.image == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    try {
      // Convert base64 to image
      final imageData = base64Decode(message.image!);

      // Generate a unique and stable tag for hero animations
      final heroTag =
          'image_${message.timestamp.millisecondsSinceEpoch}_${message.hashCode}';

      return GestureDetector(
        onTap: () => _showFullScreenImage(context, imageData, heroTag),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use RepaintBoundary to improve rendering performance
            RepaintBoundary(
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    width: 220,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Stack(
                      fit: StackFit
                          .expand, // Ensure stack children fill the container
                      children: [
                        // The loading indicator UI
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              CircularProgressIndicator(
                                color: Colors.red.shade300,
                                strokeWidth: 3,
                              ),
                            ],
                          ),
                        ),

                        // Image with BoxFit.cover to ensure it fills the space
                        Image.memory(
                          imageData,
                          fit: BoxFit
                              .cover, // This ensures image covers the entire area
                          width: 220,
                          height: 200,
                          alignment: Alignment.center, // Center the image
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback:
                              true, // Prevents flickering when image changes
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                            if (frame != null) {
                              // Show with fade-in animation when loaded
                              return FadeTransition(
                                opacity:
                                    Tween<double>(begin: 0, end: 1).animate(
                                  CurvedAnimation(
                                    parent: const AlwaysStoppedAnimation(1),
                                    curve: Curves.easeInOut,
                                    reverseCurve: Curves.easeInOut,
                                  ),
                                ),
                                child: child,
                              );
                            }
                            return const SizedBox
                                .shrink(); // Empty box while loading
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              width: 220,
                              height: 200,
                              color: Colors.red.shade100,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error,
                                        color: Colors.red, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      'Image failed to load',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  message.text,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
          ],
        ),
      );
    } catch (e) {
      print('Error decoding image: $e');
      return Container(
        width: 220,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.red),
              SizedBox(height: 8),
              Text(
                'Image could not be loaded',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showFullScreenImage(
      BuildContext context, Uint8List imageData, String heroTag) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  imageData,
                  fit: BoxFit.contain, // Use contain for fullscreen view
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
