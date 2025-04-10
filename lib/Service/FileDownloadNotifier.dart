import 'package:flutter/foundation.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';

class FileDownloadNotifier extends ChangeNotifier {
  static final FileDownloadNotifier _instance =
      FileDownloadNotifier._internal();
  static FileDownloadNotifier get instance => _instance;

  Map<String, dynamic>? _downloadData;
  Map<String, dynamic>? get value => _downloadData;

  FileDownloadNotifier._internal();

  void updateFileDownload(Map<String, dynamic> data) {
    _downloadData = data;
    notifyListeners();
  }
}
