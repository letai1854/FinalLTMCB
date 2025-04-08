import 'dart:io';
import 'dart:developer' as logger;
import 'package:finalltmcb/ClientUdp/udp_client_singleton.dart';
import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/constants/GlobalVariables.dart';
import 'Models/file_constants.dart';

/// Stores the current state of the UDP chat client, including
/// connection details and session information.
class ClientStateForFile {
  final String serverHost;
  final int serverPort;
  final RawDatagramSocket socket;
  final InternetAddress serverAddress;
  String? sessionKey = UdpClientSingleton().clientState?.sessionKey;
  String? currentUserId = UdpClientSingleton().clientState?.currentChatId;
  bool running = true;
  final int portNew;
  List<Map<String, dynamic>> rooms = [];
  // Danh sách tất cả người dùng
  List<String> allUsers = [];
  // Map lưu trữ tin nhắn theo roomId
  Map<String, List<dynamic>> allMessages = {};

  // Converted data structures

  /// Private constructor - use ClientState.create() factory constructor instead
  ClientStateForFile._internal(this.serverHost, this.serverPort, this.socket,
      this.serverAddress, this.portNew) {
    rooms = [];
    allUsers = [];
    allMessages = {};
  }

  /// Factory constructor that creates the socket and resolves the server address
  static Future<ClientStateForFile> create(
      String serverHost, int serverPort, int portFile) async {
    try {
      logger.log("File transfer client created with session key:");

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
            orElse: () => addresses.first);
        logger.log(
            "Resolved hostname to: ${resolvedAddress.address} (${resolvedAddress.type})");
      }

      logger.log("Creating UDP socket...");
      // Create UDP socket using FILE_TRANSFER_SERVER_PORT
      var a = GlobalVariables.instance.port;
      print(a);
      final socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, portFile);

      logger.log("Socket created. Local port: ${socket.port}");

      return ClientStateForFile._internal(
          serverHost, serverPort, socket, resolvedAddress, portFile);
    } catch (e) {
      logger.log("Failed to initialize client state: $e");
      throw Exception('Failed to initialize file client state: $e');
    }
  }

  /// Close the socket when done
  void closeSocket() {
    if (socket != null) {
      socket.close();
      logger.log("Socket closed");
    }
  }

  void close() {
    running = false;
    closeSocket();
  }
}
