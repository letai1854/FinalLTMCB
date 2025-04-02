import 'dart:io';

import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/Screen/Chat/ChatMobile.dart';
import 'package:finalltmcb/Screen/Chat/Responsivechat.dart';
import 'package:finalltmcb/Screen/Chat/listUserMobile.dart';
import 'package:finalltmcb/Screen/Login/ResponsiveLogin.dart';
import 'package:finalltmcb/Screen/SignUp/ReponsiveSignUp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_strategy/url_strategy.dart';
import 'package:video_player/video_player.dart';
// Add media_kit import
import 'package:media_kit/media_kit.dart';

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
          case '/chatMobile':
            // Check if we have user ID in arguments
            if (args is Map<String, dynamic> && args.containsKey('userId')) {
              return PageRouteBuilder(
                pageBuilder: (context, _, __) =>
                    ChatMobile(userId: args['userId']),
                settings: settings,
              );
            }
            // Fallback to user list if no user ID provided
            return PageRouteBuilder(
              pageBuilder: (context, _, __) => const ListUserMobile(),
              settings: settings,
            );
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

          default:
            return PageRouteBuilder(
                pageBuilder: (context, _, __) => const ResponsiveLogin(),
                settings: const RouteSettings(name: '/login'));
          // pageBuilder: (context, _, __) => const ListUserMobile(),
          // settings: const RouteSettings(name: '/chatMobile'));
        }
      },
    );
  }
}
