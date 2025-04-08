import 'dart:async';
import 'dart:io';
import 'dart:developer' as logger;

import 'package:finalltmcb/ClientUdp/caesar_cipher.dart';

import 'client_state.dart';
import 'command_processor.dart';
import 'constants.dart';
import 'handshake_manager.dart';
import 'message_listener.dart';
import 'message_processor.dart';

// Main entry point for command line use
void main(List<String> args) async {
  final String DEFAULT_SERVER_HOST = "localhost";

  String host = DEFAULT_SERVER_HOST;
  int port = Constants.DEFAULT_SERVER_PORT;

  logger.log('Starting UDP Chat Client...');

  // Parse command line arguments
  if (args.length >= 1) {
    host = args[0];
    logger.log('Using provided host: $host');
  } else {
    logger.log('Using default host: $host');
  }

  if (args.length >= 2) {
    try {
      port = int.parse(args[1]);
      logger.log('Using provided port: $port');
    } catch (e) {
      stderr.writeln(
          "Invalid port number provided: ${args[1]}. Using default port $port.");
      logger.log("Invalid port argument '${args[1]}', using default $port");
    }
  } else {
    logger.log('Using default port: $port');
  }

  // Check for direct login command
  String? loginCommand;
  if (args.length >= 4 && args[2].toLowerCase() == 'login') {
    loginCommand = '/login ${args[3]} ${args.length >= 5 ? args[4] : ""}';
    logger.log('Found login command: $loginCommand (username: ${args[3]})');
  }

  try {
    logger.log('Creating UDP client for $host:$port...');
    UdpChatClient client = await UdpChatClient.create(host, port);

    // If we have a login command, process it immediately
    if (loginCommand != null) {
      logger.log('Processing login command: $loginCommand');
      client.commandProcessor.processCommand(loginCommand);

      // Wait a moment to let communication happen
      logger.log('Waiting for server response...');
      await Future.delayed(Duration(seconds: 5));
      logger.log('Login attempt completed');
    }

    // Only start the full interactive client if no direct login was requested
    if (loginCommand == null) {
      logger.log('Starting interactive client mode...');
      await client.start();
    } else {
      // Just clean up after direct login attempt
      client.cleanup();
    }
  } catch (e) {
    stderr.writeln("An unexpected error occurred: $e");
    logger.log("Unexpected error during client startup: $e");
  }
}

// Helper for Flutter to send a direct command and wait for response
Future<void> processCommand(UdpChatClient client, String command) async {
  logger.log('Processing command from Flutter: $command');
  client.commandProcessor.processCommand(command);
  // Wait a moment for server to process and respond
  logger.log('Waiting for server response to: $command');
  await Future.delayed(Duration(milliseconds: 500));
  logger.log('Command processing completed: $command');
}

Future<void> startUdpService() async {
  print("Starting UDP client for Flutter environment...");
  logger.log("Initializing UDP client for Flutter environment");

  // Run encryption test before anything else
  logger.log("Running encryption comparison test...");
  // CaesarCipher.runComparisonTest();
}

class UdpChatClient {
  final ClientState clientState;
  final MessageProcessor messageProcessor;
  final HandshakeManager handshakeManager;
  final CommandProcessor commandProcessor;
  final MessageListener messageListener;

  UdpChatClient(this.clientState, this.messageProcessor, this.handshakeManager,
      this.commandProcessor, this.messageListener);

  // Factory constructor for creating the client with all its dependencies
  static Future<UdpChatClient> create(String serverHost, int serverPort) async {
    logger
        .log("Initializing UDP Chat Client for server $serverHost:$serverPort");

    // Create ClientState (contains socket)
    logger.log("Creating ClientState with socket...");
    final clientState = await ClientState.create(serverHost, serverPort);
    logger.log("ClientState created. Local port: ${clientState.socket.port}");

    // Order matters: MessageProcessor needs ClientState
    logger.log("Creating MessageProcessor...");
    final messageProcessor = MessageProcessor(clientState);

    // HandshakeManager needs ClientState and MessageProcessor
    logger.log("Creating HandshakeManager...");
    final handshakeManager = HandshakeManager(clientState, messageProcessor);

    // CommandProcessor needs ClientState and HandshakeManager
    logger.log("Creating CommandProcessor...");
    final commandProcessor = CommandProcessor(clientState, handshakeManager);

    // MessageListener needs ClientState and HandshakeManager
    logger.log("Creating MessageListener...");
    final messageListener = MessageListener(clientState, handshakeManager);

    logger.log("Client components initialized successfully.");

    return UdpChatClient(clientState, messageProcessor, handshakeManager,
        commandProcessor, messageListener);
  }

  Future<void> start() async {
    // Start the message listener
    logger.log("Starting message listener...");
    await messageListener.start();
    logger.log("Message listener started in the background.");

    // Show initial help message
    logger.log("Showing help message...");
    commandProcessor.showHelp();

    // Main input loop for CLI usage
    try {
      stdin.lineMode = true;
      logger.log("Entering main input loop for command processing.");

      while (clientState.running) {
        stdout.write("> ");
        String? line = stdin.readLineSync();
        if (line != null) {
          logger.log("Processing user command: $line");
          commandProcessor.processCommand(line);
        } else {
          // Add a small delay to prevent busy-waiting
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      logger.log("Error reading user input: $e");
      clientState.running = false;
    } finally {
      logger.log("Exiting main input loop.");
      cleanup();
    }
  }

  void cleanup() {
    logger.log("Starting client cleanup...");

    // Ensure running state is false to signal listener thread
    clientState.running = false;
    logger.log("Set client running state to false.");

    // Close the socket
    logger.log("Closing UDP socket...");
    clientState.closeSocket();
    logger.log("UDP socket closed.");

    // Shutdown handshake manager (clears pending requests)
    logger.log("Shutting down HandshakeManager...");
    handshakeManager.shutdown();
    logger.log("HandshakeManager shutdown complete.");

    logger.log("Client cleanup finished.");
    print("\nClient connection closed.");
  }

  // Method for Flutter compatibility - non-blocking start
  Future<void> startForFlutter() async {
    // Only start the listener - don't start the input loop
    logger.log("Starting message listener for Flutter...");
    await messageListener.start();
    logger.log("Message listener started for Flutter environment.");
  }
}
