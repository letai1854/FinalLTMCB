import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

// Conditional import for web
// This will be ignored on non-web platforms
import 'dart:html' if (dart.library.io) './fake_html.dart' as html;

// Create a fake html implementation for non-web platforms
class FakeBlob {}

class FakeUrl {
  static String createObjectUrlFromBlob(dynamic _) => '';
  static void revokeObjectUrl(String _) {}
}

class FakeAnchorElement {
  FakeAnchorElement({String? href});
  void click() {}
  void setAttribute(String name, String value) {}
}

// If we're on a non-web platform, use our fake classes
class _WebHelper {
  static dynamic createBlob(List<dynamic> data) {
    if (kIsWeb) {
      // On web, use real html.Blob
      return html.Blob(data);
    }
    // On non-web, use our fake implementation
    return FakeBlob();
  }

  static String createObjectUrl(dynamic blob) {
    if (kIsWeb) {
      return html.Url.createObjectUrlFromBlob(blob);
    }
    return '';
  }

  static void revokeObjectUrl(String url) {
    if (kIsWeb) {
      html.Url.revokeObjectUrl(url);
    }
  }

  static void downloadWithAnchor(String url, String fileName) {
    if (kIsWeb) {
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..setAttribute('style', 'display: none')
        ..click();
    }
  }
}

class FileMessage {
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String filePath; // Local path for native platforms
  final Uint8List? fileBytes; // File bytes for web platform

  const FileMessage({
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.filePath,
    this.fileBytes,
  });

  // Helper to determine if the message has file bytes (for web)
  bool get hasFileBytes => fileBytes != null && fileBytes!.isNotEmpty;

  // Helper to get a readable file size
  String get readableSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024)
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Helper to get an icon based on mime type
  IconData get icon {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType.startsWith('text/')) return Icons.text_snippet;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document'))
      return Icons.article;
    if (mimeType.contains('excel') || mimeType.contains('sheet'))
      return Icons.table_chart;
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint'))
      return Icons.slideshow;
    return Icons.insert_drive_file;
  }
}

class FilePickerUtil {
  // Pick a file and return FileMessage
  static Future<FileMessage?> pickFile(BuildContext context) async {
    try {
      // Show loading indicator (optional)
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Set options for file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb, // Only load file data on web
        dialogTitle: 'Select a file to share',
      );

      // Hide any snackbar after selection
      scaffoldMessenger.hideCurrentSnackBar();

      if (result == null || result.files.isEmpty) {
        print('📁 No file selected');
        return null;
      }

      final file = result.files.first;
      print('📁 File selected: ${file.name}, size: ${file.size} bytes');

      // Create file message from result
      return FileMessage(
        fileName: file.name,
        mimeType: getMimeType(file.name),
        fileSize: file.size,
        filePath: file.path ?? '',
        fileBytes: file.bytes,
      );
    } catch (e) {
      print('📁 Error picking file: $e');
      return null;
    }
  }

  // Helper method to get mime type from file extension
  static String getMimeType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();

    // Common MIME types based on extension
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.mp3':
        return 'audio/mpeg';
      case '.mp4':
        return 'video/mp4';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream'; // Generic binary file
    }
  }
}

// Widget to display a file in chat
class FileBubble extends StatelessWidget {
  final FileMessage file;
  final bool isMe;
  final VoidCallback onTap;

  const FileBubble({
    Key? key,
    required this.file,
    required this.isMe,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: isMe ? Colors.red.shade100 : Colors.grey.shade200,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // File icon
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    file.icon,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),

                // File details
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        file.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        file.readableSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Download icon
                const SizedBox(width: 8),
                Icon(
                  Icons.download_rounded,
                  color: Colors.red.shade700,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Create a separate helper class for downloading files
class FileDownloader {
  static Future<void> downloadFile(
      FileMessage file, BuildContext context) async {
    try {
      if (kIsWeb) {
        // Web implementation
        if (file.hasFileBytes) {
          // Hiển thị thông báo đang tải
          _showTopNotification(context, 'Đang tải ${file.fileName}...');

          // Create a blob and trigger download
          final blob = _WebHelper.createBlob([file.fileBytes!]);
          final url = _WebHelper.createObjectUrl(blob);

          // Trigger download
          _WebHelper.downloadWithAnchor(url, file.fileName);

          // Clean up
          _WebHelper.revokeObjectUrl(url);

          // Hiển thị thông báo tải thành công
          _showTopNotification(context, 'Đã tải ${file.fileName} thành công',
              isSuccess: true);
        } else {
          _showTopNotification(context, 'Không thể tải: File không có dữ liệu',
              isError: true);
        }
      } else {
        // Native platform implementation
        if (file.filePath.isNotEmpty) {
          final filePath = file.filePath;

          try {
            final fileExists = await File(filePath).exists();
            if (fileExists) {
              // Hiển thị thông báo ở trên cùng
              _showTopNotification(context, 'File có sẵn tại: ${file.fileName}',
                  isSuccess: true);
            } else {
              _showTopNotification(
                  context, 'Không tìm thấy file: ${file.fileName}',
                  isError: true);
            }
          } catch (e) {
            print('Error checking file: $e');
            _showTopNotification(
                context, 'Lỗi truy cập file: ${e.toString().split('\n').first}',
                isError: true);
          }
        } else {
          _showTopNotification(context, 'Không có đường dẫn file',
              isError: true);
        }
      }
    } catch (e) {
      print('Error downloading file: $e');
      _showTopNotification(
          context, 'Lỗi xử lý file: ${e.toString().split('\n').first}',
          isError: true);
    }
  }

  // Phương thức hiển thị thông báo ở phía trên màn hình
  static void _showTopNotification(BuildContext context, String message,
      {bool isError = false, bool isSuccess = false, Duration? duration}) {
    // Xác định màu sắc dựa trên loại thông báo
    final Color backgroundColor = isError
        ? Colors.red.shade700
        : isSuccess
            ? Colors.green.shade700
            : Colors.blue.shade700;

    // Sử dụng overlay để hiển thị thông báo ở phía trên
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                Icon(
                    isError
                        ? Icons.error_outline
                        : isSuccess
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                    color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Tự động đóng sau một khoảng thời gian
    Future.delayed(duration ?? Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
