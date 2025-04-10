import 'package:finalltmcb/File/Models/MessageContentParser.dart';
import 'package:flutter/material.dart';

class MediaPlaceholder extends StatefulWidget {
  final MediaInfo mediaInfo;
  final bool isLoading;
  final Widget? child;

  const MediaPlaceholder({
    Key? key,
    required this.mediaInfo,
    this.isLoading = false,
    this.child,
  }) : super(key: key);

  @override
  State<MediaPlaceholder> createState() => _MediaPlaceholderState();
}

class _MediaPlaceholderState extends State<MediaPlaceholder> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[300],
      child: widget.isLoading
          ? Center(child: CircularProgressIndicator())
          : widget.child ?? Icon(_getIconForType(widget.mediaInfo.fileType)),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }
}
