import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/custom/notification.dart';
import 'package:harvest_guard/firebase_options.dart';
import 'package:harvest_guard/front_page/login_page.dart';
import 'package:harvest_guard/front_page/register_page.dart';
import 'package:harvest_guard/home/auctions/auction_page.dart';
import 'package:harvest_guard/home/chats/chat_page.dart';
import 'package:harvest_guard/home/guest_home_page.dart';
import 'package:harvest_guard/home/shipping/shipment_page.dart';
import 'package:harvest_guard/services/chat.dart';
import 'package:harvest_guard/settings/settings_page.dart';
import 'package:harvest_guard/slide_page.dart';
import 'package:harvest_guard/services/version_checker.dart';
import 'package:harvest_guard/theme.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'settings/settings_provider.dart';

import 'package:provider/provider.dart';

import 'front_page.dart';
import 'global.dart';
import 'home/home_page.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity
  );
  // await FirebaseAuth.instance.useAuthEmulator('192.168.18.102', 5555);


  // allow notifications permissions
  await Permission.notification.request();

  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, "address.db");

  // Check if the database already exists
  var exists = await databaseExists(path);

  if (!exists) {
    // Make sure the parent directory exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Copy from asset
    ByteData data =
        await rootBundle.load(join("assets", "databases", "address.db"));
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Write and flush the bytes to the file
    await File(path).writeAsBytes(bytes, flush: true);
  } else {
    print("Database already exists at $path");
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent));

  _createNotificationChannels();
  runApp(const MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize notifications
  await VersionChecker.initNotifications();

}


Future<void> _createNotificationChannels() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel messagesChannel = AndroidNotificationChannel(
    'messages_channel',
    'Message Notifications',
    description: 'Channel for receiving chat messages',
    importance: Importance.max,
  );

  const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
    'notifications_channel',
    'General Notifications',
    description: 'Channel for other app notifications',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(messagesChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(generalChannel);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        child: ChangeNotifierProvider(
            create: (context) => chatDatabase,
            child: ChangeNotifierProvider(
                create: (context) => auctionDatabase,
                child: ChangeNotifierProvider(
                    create: (context) => shipmentDatabase,
                child: ChangeNotifierProvider(
                    create: (context) => notificationDatabase,
                    child: ChangeNotifierProvider(
                      create: (context) => SettingsProvider(),
                      builder: (context, _) {
                        final settingsProvider =
                            Provider.of<SettingsProvider>(context);
                        return DynamicColorBuilder(
                          builder: (ColorScheme? lightColorScheme,
                              ColorScheme? darkColorScheme) {
                            return MaterialApp(
                              title: 'HarvestGuard',
                              theme: ThemeData(
                                  pageTransitionsTheme:
                                      const PageTransitionsTheme(
                                    builders: <TargetPlatform,
                                        PageTransitionsBuilder>{
                                      // Set the predictive back transitions for Android.
                                      TargetPlatform.android:
                                          PredictiveBackPageTransitionsBuilder(),
                                    },
                                  ),
                                  colorScheme: settingsProvider.isDynamicTheming
                                      ? lightColorScheme
                                      : MaterialTheme.lightScheme()
                                          .toColorScheme()
                                          .copyWith(
                                            surfaceTint:
                                                MaterialTheme.lightScheme()
                                                    .toColorScheme()
                                                    .surfaceTint,
                                          )),
                              darkTheme: ThemeData(
                                  pageTransitionsTheme:
                                      const PageTransitionsTheme(
                                    builders: <TargetPlatform,
                                        PageTransitionsBuilder>{
                                      // Set the predictive back transitions for Android.
                                      TargetPlatform.android:
                                          PredictiveBackPageTransitionsBuilder(),
                                    },
                                  ),
                                  colorScheme: settingsProvider.isDynamicTheming
                                      ? darkColorScheme
                                      : MaterialTheme.darkScheme()
                                          .toColorScheme()
                                          .copyWith(
                                            surfaceTint:
                                                MaterialTheme.darkScheme()
                                                    .toColorScheme()
                                                    .surfaceTint,
                                          )),
                              themeMode: settingsProvider.themeMode,
                              home: Builder(
                                builder: (context) {
                                  if (Platform.isAndroid &&
                                      !VersionChecker.hasChecked) {
                                    VersionChecker.hasChecked = true;
                                    VersionChecker.checkForUpdate(context);
                                  }
                                  return FirebaseAuth.instance.currentUser !=
                                          null
                                      ? MultiProvider(providers: [
                                          ChangeNotifierProvider(
                                            create: (_) => chatDatabase,
                                          ),
                                          ChangeNotifierProvider(
                                            create: (_) =>
                                                auctionDatabase,
                                          ),
                                          ChangeNotifierProvider(
                                            create: (_) =>
                                                notificationDatabase),
                                        ], child: const HomePage())
                                      : const InitialPage();
                                },
                              ),
                              debugShowCheckedModeBanner: false,
                              navigatorKey: navigatorKeyMain,
                              onGenerateRoute: (RouteSettings settings) {
                                Map<String, dynamic> arguments =
                                    settings.arguments as Map<String, dynamic>;
                                final fromWidget = arguments['from'];

                                switch (settings.name) {
                                  case '/':
                                    return SlidePageRoute(
                                        builder: (_) => const InitialPage(),
                                        previousContext: context,
                                        settings: settings);
                                  case '/login':
                                    return SlidePageRoute(
                                        builder: (_) => const LoginPage(),
                                        previousContext: context,
                                        settings: settings);
                                  case '/register':
                                    return SlidePageRoute(
                                        builder: (_) => const RegisterPage(),
                                        previousContext: context,
                                        settings: settings);
                                  case '/home':
                                    return SlidePageRoute(
                                        builder: (_) => MultiProvider(
                                              providers: [
                                                ChangeNotifierProvider(
                                                  create: (context) =>
                                                      chatDatabase,
                                                ),
                                                ChangeNotifierProvider(
                                                  create: (context) =>
                                                      auctionDatabase,
                                                )
                                              ],
                                              child: const HomePage(),
                                            ),
                                        previousContext: context,
                                        settings: settings);
                                  case '/guest-home':
                                    return SlidePageRoute(
                                        builder: (_) => const GuestHomePage(),
                                        previousContext: context,
                                        settings: settings);
                                  case '/delivery-tracking':
                                    return SlidePageRoute(
                                        builder: (_) => DeliveryTrackingPage(
                                              shipmentId:
                                                  arguments['shipmentId'],
                                              shippingData:
                                                  arguments['shippingData'],
                                            ),
                                        previousContext: context,
                                        settings: settings);
                                  case '/auction':
                                    return SlidePageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                              create: (context) =>
                                                  auctionDatabase,
                                              child: AuctionPage(
                                                  auctionUid:
                                                      arguments['auctionUid']
                                                          as String),
                                            ),
                                        previousContext: context,
                                        settings: settings);
                                  case '/chat':
                                    return SlidePageRoute(
                                        builder: (_) => ChangeNotifierProvider(
                                              create: (context) => chatDatabase,
                                              child: ChatPage(
                                                  chat: arguments['chat']
                                                      as Chat),
                                            ),
                                        previousContext: context,
                                        settings: settings);
                                  case '/settings':
                                    return SlidePageRoute(
                                        builder: (_) => const SettingsPage(),
                                        previousContext: context,
                                        settings: settings);
                                  case '/notifications':
                                    return SlidePageRoute(
                                        builder: (_) =>
                                            const NotificationPage(),
                                        previousContext: context,
                                        settings: settings);
                                }
                                return null;
                              },
                            );
                          },
                        );
                      },
                    )
                  )
                )
              )
            )
          );
  }
}

class DeliveryTrackingArguments {
  final String shipmentId;
  final Map<String, dynamic> shippingData;

  DeliveryTrackingArguments({
    required this.shipmentId,
    required this.shippingData,
  });
}
