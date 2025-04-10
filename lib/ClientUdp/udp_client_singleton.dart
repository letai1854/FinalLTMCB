import 'package:finalltmcb/ClientUdp/udpmain.dart';
import 'package:finalltmcb/ClientUdp/client_state.dart';

class UdpClientSingleton {
  static final UdpClientSingleton _instance = UdpClientSingleton._internal();
  UdpChatClient? _client;
  ClientState? _clientState;

  // Private constructor
  UdpClientSingleton._internal();

  // Factory constructor
  factory UdpClientSingleton() {
    return _instance;
  }

  // Initialize the UDP client
  Future<void> initialize(String host, int port) async {
    if (_client == null) {
      _client = await UdpChatClient.create(host, port);
      _clientState = _client?.clientState;
      await _client?.startForFlutter();
    }
  }

  // Getter for the UDP client instance
  UdpChatClient? get client => _client;

  // Getter for the client state
  ClientState? get clientState => _clientState;

  // Method to close the connection
  void dispose() {
    _clientState?.socket?.close();
    _client = null;
    _clientState = null;
  }

  // Check if client is initialized
  bool get isInitialized => _client != null;
}
