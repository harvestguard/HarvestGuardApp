import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/firebase_options.dart';
import 'package:harvest_guard/front_page/login_page.dart';
import 'package:harvest_guard/front_page/register_page.dart';
import 'package:harvest_guard/home/auctions/auction_page.dart';
import 'package:harvest_guard/home/chats/chat_page.dart';
import 'package:harvest_guard/home/guest_home_page.dart';
import 'package:harvest_guard/home/shipping/shipment_page.dart';
import 'package:harvest_guard/home/shipping/shipments_page.dart';
import 'package:harvest_guard/services/chat.dart';
import 'package:harvest_guard/settings/settings_page.dart';
import 'package:harvest_guard/slide_page.dart';
import 'package:harvest_guard/theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'settings/settings_provider.dart';

import 'package:provider/provider.dart';

import 'front_page.dart';
import 'global.dart';
import 'home/home_page.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await FirebaseAuth.instance.useAuthEmulator('192.168.18.102', 5555);

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
  runApp(const MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child:  ChangeNotifierProvider(
        create: (context) => ChatDatabase(),
        child: ChangeNotifierProvider(
            create: (context) => AuctionDatabase(),
            child: ChangeNotifierProvider(
                create: (context) => ShipmentDatabase(),
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
                              pageTransitionsTheme: const PageTransitionsTheme(
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
                                        surfaceTint: MaterialTheme.lightScheme()
                                            .toColorScheme()
                                            .surfaceTint,
                                      )),
                          darkTheme: ThemeData(
                              pageTransitionsTheme: const PageTransitionsTheme(
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
                                        surfaceTint: MaterialTheme.darkScheme()
                                            .toColorScheme()
                                            .surfaceTint,
                                      )),
                          themeMode: settingsProvider.themeMode,
                          home: FirebaseAuth.instance.currentUser != null
                              ? MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider(
                                      create: (context) => chatDatabase,
                                    ),
                                    ChangeNotifierProvider(
                                      create: (context) => auctionDatabase,
                                    )
                                  ],
                                  child: const HomePage(),
                                )
                              : const InitialPage(),
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
                                              create: (context) => chatDatabase,
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
                                          shipmentId: arguments['shipmentId'],
                                          shippingData:
                                              arguments['shippingData'],
                                        ),
                                    previousContext: context,
                                    settings: settings);
                              case '/auction':
                                return SlidePageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                          create: (context) => auctionDatabase,
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
                                              chat: arguments['chat'] as Chat),
                                        ),
                                    previousContext: context,
                                    settings: settings);
                              case '/settings':
                                return SlidePageRoute(
                                    builder: (_) => const SettingsPage(),
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
