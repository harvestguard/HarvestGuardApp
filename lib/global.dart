import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/listener.dart';

GlobalKey<NavigatorState> navigatorKeyMain = GlobalKey();
GlobalKey<NavigatorState> navItemHome = GlobalKey();
GlobalKey<NavigatorState> navItemChats = GlobalKey();
GlobalKey<NavigatorState> navItemAuctions = GlobalKey();
GlobalKey<NavigatorState> navItemShipments = GlobalKey();
GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
GlobalKey<ScaffoldState> loadingScaffoldKey = GlobalKey<ScaffoldState>();

late ChatDatabase chatDatabase;
late AuctionDatabase auctionDatabase;
late ShipmentDatabase shipmentDatabase;
late NotificationDatabase notificationDatabase;
// global key for theme switch between material you and custom





extension MediaQueryDataProportionate on MediaQueryData {
  /// 812 is the layout height that designer use
  static const double layoutHeight = 812.0;

  /// 375 is the layout width that designer use
  static const double layoutWidth = 315.0;

  /// Get the proportionate height as per screen size.
  double getProportionateScreenHeight(double inputHeight) =>
      (inputHeight / layoutHeight) * size.height;

  /// Get the proportionate height as per screen size.
  double getProportionateScreenWidth(double inputWidth) =>
      (inputWidth / layoutWidth) * size.width;
}


