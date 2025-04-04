// import 'dart:async';
// import 'dart:io';
// import 'dart:isolate';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:developer' as logger;

// import 'package:finalltmcb/ClientUdp/client_state.dart';
// import 'package:finalltmcb/ClientUdp/command_processor.dart';
// import 'package:finalltmcb/ClientUdp/constants.dart';
// import 'package:finalltmcb/ClientUdp/handshake_manager.dart';
// import 'package:finalltmcb/ClientUdp/message_listener.dart';
// import 'package:finalltmcb/ClientUdp/message_processor.dart';
// import 'package:finalltmcb/ClientUdp/json_helper.dart';

// class UdpService {
//   static final List<Function(dynamic)> _messageHandlers = [];
//   static ReceivePort? _receivePort;
//   static SendPort? _isolateSendPort;

//   // Register a message handler to receive messages from UDP client
//   static void registerMessageHandler(Function(dynamic) handler) {
//     _messageHandlers.add(handler);
//   }

//   // Make this method public by removing the underscore
//   static void notifyHandlers(dynamic message) {
//     for (var handler in _messageHandlers) {
//       handler(message);
//     }
//   }
// }

// // Entry point for the UDP service isolate
// void udpServiceEntry(SendPort mainSendPort) async {
//   try {
//     logger.log("Starting UDP service in isolate");

//     // Create a receive port for the isolate
//     final isolateReceivePort = ReceivePort();

//     // Send the isolate's SendPort back to the main isolate
//     mainSendPort.send(isolateReceivePort.sendPort);

//     // Configure your UDP client - use IP address instead of hostname
//     final String DEFAULT_SERVER_HOST = "127.0.0.1"; // Use IP address for better reliability
//     final int port = Constants.DEFAULT_SERVER_PORT;
    
//     logger.log("Attempting to connect to UDP server at $DEFAULT_SERVER_HOST:$port");
//     mainSendPort.send("Connecting to $DEFAULT_SERVER_HOST:$port");

//     // Create UDP client with explicit error handling
//     UdpChatClient? client;
//     try {
//       client = await UdpChatClient.create(DEFAULT_SERVER_HOST, port);
//       mainSendPort.send("UDP client started successfully");
      
//       // Listen for messages from the main isolate
//       isolateReceivePort.listen((message) {
//         if (message is Map<String, dynamic>) {
//           if (message.containsKey('command')) {
//             // Direct command handling like in Java version
//             _handleDirectCommand(message, client!, mainSendPort);
//           } else if (message.containsKey('type') && message['type'] == 'ping') {
//             // Handle ping command
//             _pingServer(client!, mainSendPort, message['requestId']);
//           }
//         }
//       });

//       // Start the UDP client in background mode
//       await client.startBackground(mainSendPort);
//     } catch (e) {
//       logger.log("Error starting UDP client: $e");
//       mainSendPort.send({"error": "Failed to start UDP client: $e"});
      
//       // Try reconnecting every 5 seconds
//       Timer.periodic(Duration(seconds: 5), (timer) async {
//         try {
//           logger.log("Attempting to reconnect...");
//           mainSendPort.send("Attempting to reconnect...");
//           client = await UdpChatClient.create(DEFAULT_SERVER_HOST, port);
//           if (client != null) {
//             mainSendPort.send("Reconnected successfully!");
//             timer.cancel();
//             await client.startBackground(mainSendPort);
//           }
//         } catch (e) {
//           mainSendPort.send({"error": "Reconnection failed: $e"});
//         }
//       });
//     }
//   } catch (e) {
//     logger.log("Error in UDP service: $e");
//     mainSendPort.send({"error": "Error in UDP service: $e"});
//   }
// }

// // Handle direct commands similar to Java's CommandProcessor
// void _handleDirectCommand(Map<String, dynamic> message, UdpChatClient client, SendPort mainSendPort) {
//   final String command = message['command'];
//   final String requestId = message['requestId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
  
//   logger.log("Processing command: $command (ID: $requestId)");

//   // Directly process command, similar to Java's CommandProcessor
//   if (command.startsWith('/login')) {
//     try {
//       final parts = command.split(' ');
//       if (parts.length >= 3) {
//         final chatId = parts[1];
//         final password = parts.sublist(2).join(' ');
        
//         // Create JSON data similar to Java LoginHandler
//         Map<String, dynamic> data = {
//           Constants.KEY_CHAT_ID: chatId,
//           Constants.KEY_PASSWORD: password
//         };
        
//         // Create request similar to JsonHelper.createRequest in Java
//         Map<String, dynamic> request = {
//           Constants.KEY_ACTION: Constants.ACTION_LOGIN,
//           Constants.KEY_DATA: data
//         };
        
//         // Fix: Use correct method signature without callback
//         client.handshakeManager.sendClientRequestWithAck(
//           request, 
//           Constants.ACTION_LOGIN, 
//           Constants.FIXED_LOGIN_KEY_STRING
//         ).then((_) {
//           // Check if login was successful after the request completes
//           bool success = client.clientState.sessionKey != null;
//           // Send result back to main isolate
//           mainSendPort.send({
//             'action': 'login_response',
//             'requestId': requestId,
//             'status': success ? 'success' : 'failure',
//             'message': success ? 'Login successful' : 'Login failed',
//             'chatId': chatId,
//             'sessionKey': client.clientState.sessionKey
//           });
//         }).catchError((error) {
//           mainSendPort.send({
//             'action': 'login_response',
//             'requestId': requestId,
//             'status': 'failure',
//             'message': 'Error processing login: $error',
//             'chatId': chatId
//           });
//         });
//       } else {
//         mainSendPort.send({
//           'action': 'login_response',
//           'requestId': requestId,
//           'status': 'failure',
//           'message': 'Invalid login format. Use: /login <chatid> <password>'
//         });
//       }
//     } catch (e) {
//       mainSendPort.send({
//         'action': 'login_response',
//         'requestId': requestId,
//         'status': 'failure',
//         'message': 'Error: $e'
//       });
//     }
//   } else {
//     // Handle other commands if needed
//     mainSendPort.send({
//       'action': 'command_response',
//       'requestId': requestId,
//       'status': 'unknown_command',
//       'message': 'Unknown command: ${command.split(' ')[0]}'
//     });
//   }
// }

// // Ping server to check connectivity
// void _pingServer(UdpChatClient client, SendPort mainSendPort, String requestId) {
//   try {
//     final pingData = Uint8List.fromList([1, 2, 3, 4]);
//     client.clientState.socket.send(pingData, client.clientState.serverAddress, client.clientState.serverPort);
    
//     mainSendPort.send({
//       'action': 'ping_response',
//       'requestId': requestId,
//       'status': 'success',
//       'message': 'Ping packet sent'
//     });
//   } catch (e) {
//     mainSendPort.send({
//       'action': 'ping_response',
//       'requestId': requestId,
//       'status': 'failure',
//       'message': 'Failed to ping: $e'
//     });
//   }
// }

// class UdpChatClient {
//   final ClientState clientState;
//   final MessageProcessor messageProcessor;
//   final HandshakeManager handshakeManager;
//   final CommandProcessor commandProcessor;
//   final MessageListener messageListener;

//   UdpChatClient(this.clientState, this.messageProcessor, this.handshakeManager,
//       this.commandProcessor, this.messageListener);

//   // Factory constructor for creating the client with all its dependencies
//   static Future<UdpChatClient> create(String serverHost, int serverPort) async {
//     logger.log("Initializing UDP Chat Client for server $serverHost:$serverPort");

//     // Create ClientState (contains socket)
//     final clientState = await ClientState.create(serverHost, serverPort);

//     // Order matters: MessageProcessor needs ClientState
//     final messageProcessor = MessageProcessor(clientState);

//     // HandshakeManager needs ClientState and MessageProcessor
//     final handshakeManager = HandshakeManager(clientState, messageProcessor);

//     // CommandProcessor needs ClientState and HandshakeManager
//     final commandProcessor = CommandProcessor(clientState, handshakeManager);

//     // MessageListener needs ClientState and HandshakeManager
//     final messageListener = MessageListener(clientState, handshakeManager);

//     logger.log("Client components initialized.");

//     return UdpChatClient(
//       clientState,
//       messageProcessor,
//       handshakeManager,
//       commandProcessor,
//       messageListener
//     );
//   }

//   // Modified start method to communicate with main isolate
//   Future<void> startBackground(SendPort mainSendPort) async {
//     // Start the listener without the onMessageReceived callback
//     await messageListener.start();

//     // Set up a separate listener for UDP messages from the server
//     Timer.periodic(Duration(milliseconds: 500), (timer) {
//       if (!clientState.running) {
//         timer.cancel();
//         return;
//       }
      
//       // Check for significant state changes and send to main isolate
//       if (clientState.sessionKey != null) {
//         mainSendPort.send({
//           'login_status': 'success',
//           'chatId': clientState.currentChatId,
//           'sessionKey': clientState.sessionKey
//         });
//       }
//     });

//     logger.log("Message listener started in background mode");

//     // Create a Completer that will never complete to keep the service running
//     final Completer<void> keepAliveCompleter = Completer<void>();

//     // This will keep the service running indefinitely
//     return keepAliveCompleter.future;
//   }

//   void cleanup() {
//     logger.log("Starting client cleanup...");
//     // Ensure running state is false to signal listener thread
//     clientState.running = false;

//     // Close the socket
//     clientState.closeSocket();

//     // Shutdown handshake manager (clears pending requests)
//     handshakeManager.shutdown();

//     logger.log("Client cleanup finished.");
//   }
// }
