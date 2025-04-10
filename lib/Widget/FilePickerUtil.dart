import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:mime/mime.dart';

// Conditional import for web
// This will be ignored on non-web platforms
import 'dart:html' if (dart.library.io) './fake_html.dart' as html;

import 'package:path_provider/path_provider.dart';

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
  final int totalPackages; // New property
  final String fileType; // New property

  const FileMessage({
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.filePath,
    this.fileBytes,
    required this.totalPackages,
    required this.fileType,
  });

  // Calculate total packages based on file size
  static int calculateTotalPackages(int fileSize) {
    const int PACKAGE_SIZE = 512 * 1024; // 512KB per package
    return (fileSize / PACKAGE_SIZE).ceil();
  }

  // Determine file type from mime type
  static String getFileType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.contains('pdf')) return 'pdf';
    if (mimeType.contains('word') || mimeType.contains('document'))
      return 'document';
    if (mimeType.contains('excel') || mimeType.contains('sheet'))
      return 'spreadsheet';
    return 'file';
  }

  // Convert to JSON for server
  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'fileData': fileBytes != null ? base64Encode(fileBytes!) : null,
        'totalPackages': totalPackages,
        'fileType': fileType,
      };

  // Create from server response
  factory FileMessage.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['fileData'] != null) {
      bytes = base64Decode(json['fileData']);
    }

    return FileMessage(
      fileName: json['fileName'],
      mimeType: json['mimeType'],
      fileSize: json['fileSize'],
      filePath: '',
      fileBytes: bytes,
      totalPackages: json['totalPackages'] ?? 0,
      fileType: json['fileType'] ?? 'file',
    );
  }

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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
        dialogTitle: 'Select a file to share',
      );

      if (result == null || result.files.isEmpty) {
        print('📁 No file selected');
        return null;
      }

      final file = result.files.first;
      int fileSize;
      Uint8List fileBytes;

      // Get file size and bytes properly
      if (kIsWeb) {
        fileBytes = file.bytes ?? Uint8List(0);
        fileSize = fileBytes.length;
      } else {
        if (file.path != null) {
          final fileObj = File(file.path!);
          fileBytes = await fileObj.readAsBytes();
          fileSize = await fileObj.length();
        } else {
          fileBytes = file.bytes ?? Uint8List(0);
          fileSize = file.size;
        }
      }

      final mimeType = lookupMimeType(file.name,
              headerBytes: fileBytes.take(1024).toList()) ??
          FilePickerUtil.getMimeType(file.name);

      // Calculate total packages based on actual file size
      final totalPackages = FileMessage.calculateTotalPackages(fileSize);
      final fileType = FileMessage.getFileType(mimeType);

      print('📁 File details:');
      print('   - Name: ${file.name}');
      print('   - Size: $fileSize bytes');
      print('   - Packages: $totalPackages');
      print('   - Type: $fileType');

      return FileMessage(
        fileName: file.name,
        mimeType: mimeType,
        fileSize: fileSize,
        filePath: file.path ?? '',
        fileBytes: fileBytes,
        totalPackages: totalPackages,
        fileType: fileType,
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
        // ========= WEB IMPLEMENTATION (Giữ nguyên) =========
        if (file.hasFileBytes) {
          _showTopNotification(context, 'Đang tải ${file.fileName}...');
          final blob = _WebHelper.createBlob([file.fileBytes!]);
          final url = _WebHelper.createObjectUrl(blob);
          _WebHelper.downloadWithAnchor(url, file.fileName);
          _WebHelper.revokeObjectUrl(url);
          _showTopNotification(context, 'Đã tải ${file.fileName} thành công',
              isSuccess: true);
        } else {
          _showTopNotification(
              context, 'Không thể tải trên web: File không có dữ liệu bytes.',
              isError: true);
        }
        // ========= KẾT THÚC WEB IMPLEMENTATION =========
      } else {
        // ========= NATIVE PLATFORM IMPLEMENTATION (Sử dụng "Save As" Dialog) =========

        // 1. Kiểm tra tên file
        if (file.fileName.isEmpty) {
          _showTopNotification(context, 'Tên file không hợp lệ.',
              isError: true);
          return;
        }

        // 2. Kiểm tra đường dẫn file nguồn
        if (file.filePath.isEmpty) {
          _showTopNotification(
              context, 'Không thể lưu: Đường dẫn file nguồn bị trống.',
              isError: true);
          print('Save failed: file.filePath is empty for ${file.fileName}');
          return;
        }

        // 3. Tạo đối tượng File cho file nguồn
        final sourceFile = File(file.filePath);

        // 3.1 Kiểm tra sự tồn tại file nguồn
        if (!await sourceFile.exists()) {
          _showTopNotification(
              context, 'Lỗi: Không tìm thấy file nguồn tại ${file.filePath}',
              isError: true);
          print('Save failed: Source file does not exist at ${file.filePath}');
          return;
        }

        _showTopNotification(
            context, 'Vui lòng chọn vị trí lưu cho ${file.fileName}...');

        try {
          // 4. Mở hộp thoại "Save As" của hệ thống
          String? savePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Lưu file vào...', // Tiêu đề hộp thoại
            fileName: file.fileName, // Tên file gợi ý
          );

          // 5. Xử lý kết quả từ hộp thoại
          if (savePath != null) {
            // Người dùng đã chọn một vị trí (ví dụ: D:\MyFolder\myfile.txt)
            _showTopNotification(context, 'Đang lưu vào ${savePath}...',
                isSuccess: false, isError: false);

            try {
              // 6. Sao chép file từ nguồn đến vị trí người dùng chọn
              await sourceFile.copy(savePath);

              print('File đã được lưu thành công tại: $savePath');
              _showTopNotification(
                  context, 'Đã lưu ${file.fileName} thành công!',
                  isSuccess: true);
            } catch (e) {
              // Lỗi trong quá trình copy
              print('Lỗi khi sao chép file tới vị trí đã chọn: $e');
              String errorMessage = 'Lỗi khi lưu file';
              if (e is FileSystemException) {
                errorMessage = 'Lỗi hệ thống file khi lưu: ${e.message}';
              } else {
                errorMessage =
                    'Lỗi lưu file: ${e.toString().split('\n').first}';
              }
              _showTopNotification(context, errorMessage, isError: true);
            }
          } else {
            // Người dùng đã hủy (nhấn Cancel trong hộp thoại)
            print('Người dùng đã hủy lưu file.');
            _showTopNotification(context, 'Đã hủy thao tác lưu file.',
                isError: false);
          }
        } catch (e) {
          // Lỗi khi mở hộp thoại FilePicker
          print('Lỗi trong quá trình mở hộp thoại lưu file: $e');
          _showTopNotification(context, 'Lỗi: Không thể mở hộp thoại lưu file.',
              isError: true);
        }
        // ========= KẾT THÚC NATIVE IMPLEMENTATION =========
      }
    } catch (e) {
      // Lỗi chung
      print('Lỗi không xác định trong downloadFile: $e');
      _showTopNotification(
          context, 'Lỗi không xác định: ${e.toString().split('\n').first}',
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
