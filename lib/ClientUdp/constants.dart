class Constants {
  // Private constructor to prevent instantiation
  Constants._();

  // --- Network ---
  static const int DEFAULT_SERVER_PORT = 9876;
  static const int MAX_UDP_PACKET_SIZE = 65507;
  //file network
  static const int FILE_TRANSFER_SERVER_PORT = 9877;
  //file detail
  static final String STORAGE_DIR = "server_storage";
  static final int BUFFER_SIZE = 1024 * 64;
  static final int DATA_CHUNK_SIZE = 1024 * 32;

  // --- Security ---
  /**
   * Fixed key string used ONLY for decrypting the initial login request.
   * Its length (9) determines the Caesar shift (shift = 9).
   * DO NOT use this for encrypting replies or any other communication.
   */
  static const String FIXED_LOGIN_KEY_STRING =
      "LoginKey9"; // CRITICAL: Must match server exactly!

  /**
   * Fixed key string used ONLY for decrypting the initial register request.
   * Its length (11) determines the Caesar shift (shift = 11).
   * DO NOT use this for encrypting replies or any other communication.
   */
  static const String FIXED_REGISTER_KEY_STRING =
      "LoginKey9"; // CRITICAL: Must match server exactly!

  // --- JSON Keys ---
  // Common
  static const String KEY_ACTION = "action";
  static const String KEY_STATUS = "status";
  static const String KEY_MESSAGE = "message";
  static const String KEY_DATA = "data";
  static const String KEY_CHAT_ID = "chatid";

  // Login Action
  static const String KEY_PASSWORD = "password";
  static const String KEY_SESSION_KEY = "session_key";

  // Room Creation
  static const String KEY_PARTICIPANTS =
      "participants"; // List of chatids to add to room
  static const String KEY_ROOM_ID = "room_id";
  static const String KEY_ROOM_NAME = "room_name";

  // Send Message Action
  static const String KEY_CONTENT = "content";
  static const String KEY_SENDER_CHAT_ID = "sender_chatid";
  static const String KEY_TIMESTAMP = "timestamp";
  static const String KEY_LETTER_COUNT =
      "letter_count"; // Kept for potential compatibility, but frequencies are used now
  static const String KEY_LETTER_FREQUENCIES =
      "letter_frequencies"; // Key for frequency map in CHARACTER_COUNT and CONFIRM_COUNT
  static const String KEY_CONFIRM = "confirm"; // Boolean key in CONFIRM_COUNT
  static const String KEY_ORIGINAL_ACTION =
      "original_action"; // Key to store the action being confirmed/acked
  static const String KEY_FROM_TIME =
      "from_time"; // Key for filtering messages by time

  // --- Action Values ---
  static const String ACTION_LOGIN = "login";
  static const String ACTION_CREATE_ROOM = "create_room";
  static const String ACTION_GET_ROOMS =
      "get_rooms"; // Thêm action xem danh sách room
  static const String ACTION_GET_MESSAGES =
      "get_messages"; // Thêm action xem tin nhắn
  static const String ACTION_SEND_MESSAGE =
      "send_message"; // Initial request from client
  static const String ACTION_RECEIVE_MESSAGE =
      "receive_message"; // Server forwarding message to other clients
  static const String ACTION_ERROR = "error";
  static const String ACTION_LOGIN_SUCCESS =
      "login_success"; // Server response to login
  static const String ACTION_ROOM_CREATED =
      "room_created"; // Server response to create_room
  static const String ACTION_ROOMS_LIST =
      "rooms_list"; // Server response to get_rooms
  static const String ACTION_MESSAGES_LIST =
      "messages_list"; // Server response to get_messages
  static const String ACTION_MESSAGE_SENT =
      "message_sent"; // Final confirmation to sender after successful delivery/save

  // New actions for the 3-way handshake
  static const String ACTION_CHARACTER_COUNT =
      "character_count"; // Server -> Client (after initial Client req) OR Client -> Server (after initial Server req)
  static const String ACTION_CONFIRM_COUNT =
      "confirm_count"; // Client -> Server (response to CHARACTER_COUNT) OR Server -> Client (response to CHARACTER_COUNT)
  static const String ACTION_ACK =
      "ack"; // Server -> Client (final step for Client->Server flow) OR Client -> Server (final step for Server->Client flow)

  // Additional action values
  static const String ACTION_REGISTER = "register";
  static const String ACTION_REGISTER_SUCCESS = "register_success";
  static const String ACTION_GET_USERS = "get_users";
  static const String ACTION_USERS_LIST = "users_list";
  static const String ACTION_ADD_USER_TO_ROOM = "add_user_to_room";
  static const String ACTION_USER_ADDED = "user_added";
  static const String ACTION_REMOVE_USER_FROM_ROOM = "remove_user_from_room";
  static const String ACTION_USER_REMOVED = "user_removed";
  static const String ACTION_DELETE_ROOM = "delete_room";
  static const String ACTION_ROOM_DELETED = "room_deleted";
  static const String ACTION_RENAME_ROOM = "rename_room";
  static const String ACTION_ROOM_RENAMED = "room_renamed";
  static const String ACTION_GET_ROOM_USERS = "get_room_users";
  static const String ACTION_ROOM_USERS_LIST = "room_users_list";
  static const String ACTION_RECIEVE_ROOM = "recieve_room";
  // --- Status Values ---
  static const String STATUS_SUCCESS = "success";
  static const String STATUS_FAILURE = "failure";
  static const String STATUS_ERROR = "error";
  static const String STATUS_CANCELLED =
      "cancelled"; // Added status for ACK when confirm is false

  // --- Error Messages ---
  static const String ERROR_MSG_INVALID_JSON =
      "Invalid JSON format or decryption failed."; // Updated message
  static const String ERROR_MSG_UNKNOWN_ACTION = "Unknown action specified.";
  static const String ERROR_MSG_MISSING_FIELD = "Missing required field: ";
  static const String ERROR_MSG_AUTHENTICATION_FAILED =
      "Authentication failed. Invalid chatid or password.";
  static const String ERROR_MSG_INTERNAL_SERVER_ERROR =
      "Internal server error.";
  static const String ERROR_MSG_NOT_LOGGED_IN =
      "User not logged in or session expired.";
  static const String ERROR_MSG_ROOM_NOT_FOUND = "Room not found.";
  static const String ERROR_MSG_INVALID_TIME = "Invalid time format.";
  static const String ERROR_MSG_NOT_IN_ROOM =
      "You are not a participant in this room.";
  static const String ERROR_MSG_INVALID_CONFIRMATION =
      "Message confirmation failed (letter frequency mismatch)."; // Updated message
  static const String ERROR_MSG_INVALID_PARTICIPANTS =
      "Invalid participants list. Need at least 2 participants.";
  static const String ERROR_MSG_USER_NOT_FOUND = "One or more users not found.";
  static const String ERROR_MSG_DECRYPTION_FAILED =
      "Failed to decrypt message with provided session key."; // Added message
  static const String ERROR_MSG_PENDING_ACTION_NOT_FOUND =
      "No pending action found for this confirmation/ack.";
  static const String ERROR_MSG_INVALID_STATE =
      "Invalid state for current action.";
  static const String ACTION_RECIEVE_LISTUSER = "recieve_listuser";
  // --- Client Command Definitions ---
  static const String CMD_LOGIN = "/login";
  static const String CMD_CREATE_ROOM = "/create";
  static const String CMD_SEND = "/send";
  static const String CMD_HELP = "/help";
  static const String CMD_EXIT = "/exit";
  static const String CMD_LIST_ROOMS = "/rooms";
  static const String CMD_LIST_MESSAGES = "/messages";
  static const String CMD_REGISTER = "/register";
  static const String CMD_GET_USERS = "/users";
  static const String CMD_ADD_USER = "/adduser";
  static const String CMD_REMOVE_USER = "/removeuser";
  static const String CMD_DELETE_ROOM = "/deleteroom";
  static const String CMD_RENAME_ROOM = "/renameroom";
  static const String CMD_GET_ROOM_USERS = "/roomusers";
  static const String CMD_LOGIN_DESC =
      "/login <chatid> <password> - Đăng nhập vào hệ thống";
  static const String CMD_CREATE_ROOM_DESC =
      "/create <room_name> <user2> [user3 ...] - Tạo phòng chat với các người dùng được chỉ định";
  static const String CMD_SEND_DESC =
      "/send <room_id> <message> - Gửi tin nhắn đến phòng chat";
  static const String CMD_HELP_DESC = "/help - Hiển thị hướng dẫn này";
  static const String CMD_EXIT_DESC = "/exit - Thoát chương trình";
  static const String CMD_LIST_ROOMS_DESC =
      "/rooms - Hiển thị danh sách phòng chat của bạn";
  static const String CMD_LIST_MESSAGES_DESC =
      "/messages <room_id> [time_option] - Hiển thị tin nhắn trong phòng chat";
  static const String CMD_REGISTER_DESC =
      "/register <chatid> <password> - Register for new account";
  static const String CMD_GET_USERS_DESC = "/users - Show all users";
  static const String CMD_ADD_USER_DESC =
      "/adduser <room_id> <username> - Add a user to an existing room";
  static const String CMD_REMOVE_USER_DESC =
      "/removeuser <room_id> <username> - Remove a user from an existing room";
  static const String CMD_DELETE_ROOM_DESC =
      "/deleteroom <room_id> - Delete an existing room";
  static const String CMD_RENAME_ROOM_DESC =
      "/renameroom <room_id> <new_room_name> - Rename an existing room";
  static const String CMD_GET_ROOM_USERS_DESC =
      "/roomusers <room_id> - Get the list of users in a room";
  static const String TIME_OPTION_HOURS = "hours";
  static const String TIME_OPTION_DAYS = "days";
  static const String TIME_OPTION_WEEKS = "weeks";
  static const String TIME_OPTION_ALL = "all";
  //file action
  static final String ACTION_FILE_INIT = "file_init";
  static final String ACTION_FILE_DATA = "file_data";
  static final String ACTION_FILE_FIN = "file_fin";
  static final String ACTION_LIST_REQ = "list_req";
  static final String ACTION_DOWN_REQ = "down_req";
  static final String ACTION_DOWN_FIN = "down_fin";
  static final String ACTION_FILE_DOWN = "file_down";
  // --- Other ---
  static const int SESSION_CLEANUP_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes
  static const int SESSION_MAX_INACTIVE_INTERVAL_MS =
      30 * 60 * 1000; // 30 minutes
  static const int PENDING_MESSAGE_TIMEOUT_MS =
      60 * 1000; // 1 minute timeout for pending confirmations/acks
  static const String gemini_bot = "gemini_bot";
}
