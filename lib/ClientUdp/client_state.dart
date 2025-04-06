import 'dart:io';
import 'dart:developer' as logger;
import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';

/// Stores the current state of the UDP chat client, including
/// connection details and session information.
class ClientState {
  final String serverHost;
  final int serverPort;
  final RawDatagramSocket socket;
  final InternetAddress serverAddress;
  
  String? sessionKey;
  String? currentChatId;
  bool running = true;
 List<Map<String, dynamic>> rooms = [];
  // Danh sách tất cả người dùng
  List<String> allUsers = [];
  // Map lưu trữ tin nhắn theo roomId
  Map<String, List<dynamic>> allMessages = {};
  
  // Converted data structures
  List<User> convertedUsers = [];
  List<Map<String, dynamic>> cachedMessages = [];
  Map<String, List<ChatMessage>> roomMessages = {};

  /// Private constructor - use ClientState.create() factory constructor instead
  ClientState._internal(
    this.serverHost,
    this.serverPort,
    this.socket,
    this.serverAddress
  ) {
    rooms = [];
    allUsers = [];
    allMessages = {};
    convertedUsers = [];
    cachedMessages = [];
    roomMessages = {};
  }

  /// Factory constructor that creates the socket and resolves the server address
  static Future<ClientState> create(String serverHost, int serverPort) async {
    try {
      logger.log("Resolving server address: $serverHost");
      
      // Properly resolve the server address
      InternetAddress resolvedAddress;
      try {
        // Try to parse as direct IP address first (more reliable)
        resolvedAddress = InternetAddress(serverHost);
        logger.log("Parsed direct IP address: ${resolvedAddress.address}");
      } catch (_) {
        // If that fails, do a DNS lookup
        final addresses = await InternetAddress.lookup(serverHost);
        if (addresses.isEmpty) {
          throw Exception("Could not resolve host: $serverHost");
        }
        // Prefer IPv4 addresses when available
        resolvedAddress = addresses.firstWhere(
          (addr) => addr.type == InternetAddressType.IPv4,
          orElse: () => addresses.first
        );
        logger.log("Resolved hostname to: ${resolvedAddress.address} (${resolvedAddress.type})");
      }
      
      logger.log("Creating UDP socket...");
      // Create UDP socket (explicitly specify IPv4)
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 
        0,  // Use port 0 for automatic port assignment
        reuseAddress: true
      );
      
      logger.log("Socket created. Local port: ${socket.port}");
      
      return ClientState._internal(serverHost, serverPort, socket, resolvedAddress);
    } catch (e) {
      logger.log("Failed to initialize client state: $e");
      throw Exception('Failed to initialize client state: $e');
    }
  }

  /// Close the socket when done
  void closeSocket() {
    if (socket != null) {
      socket.close();
      logger.log("Socket closed");
    }
  }
}
