class FileConstants {
  static const int FILE_TRANSFER_SERVER_PORT = 9877;

  // File Actions
  static const String ACTION_FILE_INIT = "file_send_init";
  static const String ACTION_FILE_DATA = "file_send_data";
  static const String ACTION_FILE_FIN = "file_send_fin";
  static const String ACTION_FILE_DOWN = "file_download";
  static const String ACTION_LIST_REQ = "list_request";
  static const String ACTION_DOWN_REQ = "download_request";
  static const String ACTION_DOWN_FIN = "download_fin";

  // File Transfer Actions
  static const String ACTION_FILE_SEND_INIT = "file_send_init";
  static const String ACTION_FILE_SEND_DATA = "file_send_data";
  static const String ACTION_FILE_SEND_FIN = "file_send_fin";

  // Status codes
  static const String STATUS_SUCCESS = "success";
  static const String STATUS_ERROR = "error";
  static const String STATUS_PENDING = "pending";

  // Data Keys
  static const String KEY_CHAT_ID = "chat_id";
  static const String KEY_ROOM_ID = "room_id";
  static const String KEY_FILE_PATH = "file_path";
  static const String KEY_FILE_SIZE = "file_size";
  static const String KEY_FILE_TYPE = "file_type";
  static const String KEY_TOTAL_PACKETS = "total_packets";
}
