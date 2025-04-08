import 'dart:io';
import 'dart:developer' as logger;
import 'package:finalltmcb/ClientUdp/constants.dart';
import 'package:finalltmcb/ClientUdp/client_state.dart';
import 'package:finalltmcb/ClientUdp/udp_client_singleton.dart';
import 'package:finalltmcb/Controllers/GroupController.dart';

import 'package:finalltmcb/Controllers/MessageController.dart';
import 'package:finalltmcb/File/UdpChatClientFile.dart';

import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/Controllers/UserController.dart';
import 'package:finalltmcb/Screen/Chat/ChatMobile.dart';
import 'package:finalltmcb/Screen/Chat/Responsivechat.dart';
import 'package:finalltmcb/Screen/Chat/listUserMobile.dart';
import 'package:finalltmcb/Screen/Debug/CommandConsole.dart'; // Import the debug console
import 'package:finalltmcb/Screen/Login/ResponsiveLogin.dart';
import 'package:finalltmcb/Screen/SignUp/ReponsiveSignUp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_strategy/url_strategy.dart';
import 'package:video_player/video_player.dart';
// Add media_kit import
import 'package:media_kit/media_kit.dart';

import 'package:finalltmcb/ClientUdp/udpmain.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  // Initialize user session
  final userProvider = UserProvider();
  await userProvider.loadUserSession();

  // Start UDP service for Flutter
  await startUdpService();
}

// Function to start UDP service in Flutter environment
// Global instances
late final GroupController globalGroupController;
late final ClientState globalClientState;
late final MessageController globalMessageController;
Future<void> startUdpService() async {
  print("Starting UDP client for Flutter environment...");
  logger.log("Initializing UDP client for Flutter environment");

  // Get the singleton instance of UserController
  final userController = UserController();
  // Initialize global GroupController
  globalGroupController = GroupController.instance;
  globalMessageController = MessageController.instance;

  try {
    // Choose the right host based on platform
    String host;
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 to reach host machine
      host = "10.0.2.2";
      logger.log("Running on Android, using host: $host");
    } else {
      host = "localhost";
      logger.log("Using host: $host");
    }

    // logger.log(
    //     "Creating UdpChatClient for $host:${Constants.DEFAULT_SERVER_PORT}...");
    // UdpChatClient client =
    //     await UdpChatClient.create(host, Constants.DEFAULT_SERVER_PORT);
    final udpClientSingleton = UdpClientSingleton();
    await udpClientSingleton.initialize(host, Constants.DEFAULT_SERVER_PORT);
    final client =
        udpClientSingleton.client!; // Use the singleton's client instance

// Create the file client

    // Set global instances
    globalClientState = client.clientState;
    userController.setUdpClient(client);
    globalGroupController.setUdpClient(client);
    // globalMessageController.setUdpClient(
    //     client, udpClientSingleton.clientState?.getFilePort() ?? 0);
    // logger.log("UdpClient set in UserController");
    await globalMessageController.setUdpClient(
        client, udpClientSingleton.clientState?.getFilePort() ?? 0);

    // Test socket connection before starting
    try {
      // logger.log("Testing socket connection...");
      var socket = client.clientState.socket;
      // logger.log(
      //     "Local socket info - Port: ${socket.port}, Address: ${socket.address}");
      // logger.log(
      //     "Target server: ${client.clientState.serverAddress}:${client.clientState.serverPort}");
      // print("UDP socket ready for communication");
    } catch (e) {
      logger.log("Socket connection test failed: $e");
      print("WARNING: Socket connection test failed: $e");
    }

    // Start the client in Flutter mode (just start the listener, not the input loop)
    await client.startForFlutter();
    // logger.log("Message listener started for Flutter environment.");
    // print("UDP message listener started");
  } catch (e, stackTrace) {
    logger.log("Failed to start UDP client: $e");
    logger.log("Stack trace: $stackTrace");
    print("Failed to start UDP client: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Initialize MediaKit
  MediaKit.ensureInitialized();

  await initApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopii',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Đảm bảo có route mặc định
      onGenerateRoute: (settings) {
        // Extract the arguments from the settings
        final args = settings.arguments;

        switch (settings.name) {
          case '/login':
            if (UserProvider().currentUser == null) {
              return PageRouteBuilder(
                pageBuilder: (context, _, __) => const ResponsiveLogin(),
                settings: settings,
              );
            } else {
              return PageRouteBuilder(
                pageBuilder: (context, _, __) => const Responsivechat(),
                settings: const RouteSettings(name: '/chat'),
              );
            }
          // case '/chatMobile':
          //   // Check if we have user ID in arguments
          //   if (args is Map<String, dynamic> && args.containsKey('userId')) {
          //     return PageRouteBuilder(
          //       pageBuilder: (context, _, __) =>
          //           ChatMobile(userId: args['userId']),
          //       settings: settings,
          //     );
          //   }
          //   // Fallback to user list if no user ID provided
          //   return PageRouteBuilder(
          //     pageBuilder: (context, _, __) => const ListUserMobile(),
          //     settings: settings,
          //   );
          case '/chat':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const Responsivechat(),
              settings: settings,
            );
          case '/signup':
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ReponsiveSignUp(),
              settings: settings,
            );
          case '/debug': // Add a route for the debug console
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const CommandConsole(),
              settings: settings,
            );
          default:
            return PageRouteBuilder(
                pageBuilder: (context, _, __) => const ResponsiveLogin(),
                settings: const RouteSettings(name: '/login'));
        }
      },
    );
  }
}
