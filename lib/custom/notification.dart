import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'listener.dart'; // Ensure this import path points to your listener.dart where NotificationDatabase is defined.

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // Helper: Returns a title based on type.
  String getTitle(Map<String, dynamic> notif) {
    switch (notif['type']) {
      case 'newBid':
        return 'New Bid';
      case 'newAuction':
        return 'New Auction';
      case 'auctionUpdate':
        return 'Auction Update';
      case 'newMessagePrivate':
        return 'New Message';
      case 'updateMessagePrivate':
        return 'Message Update';
      case 'newReactPrivate':
        return 'New Reaction';
      case 'deleteMessagePrivate':
        return 'Message Deleted';
      case 'newProduct':
        return 'New Product';
      case 'updateProduct':
        return 'Product Update';
      case 'newShipment':
        return 'New Shipment';
      case 'updateShipment':
        return 'Shipment Update';
      case 'shipmentStatus':
        return 'Shipment Status';
      case 'shipmentLocation':
        return 'Shipment Location';
      case 'newUser':
        return 'New User';
      case 'updateUser':
        return 'User Update';
      default:
        return notif['type'] ?? 'Notification';
    }
  }

  // Helper: Returns a concise message based on type.
  String getConcise(Map<String, dynamic> notif) {
    switch (notif['type']) {
      case 'newBid':
        return 'A new bid has been received.';
      case 'newAuction':
        if (notif['auctionDetails'] != null && notif['auctionDetails']['adminName'] != null) {
          final admin = notif['auctionDetails']['adminName'];
          return 'New auction created by ${admin['firstName']} ${admin['lastName']}.';
        }
        return 'A new auction has been created.';
      case 'auctionUpdate':
        return 'Auction updated for product ${notif['auctionDetails']?['product'] ?? "N/A"}.';
      case 'newMessagePrivate':
        return notif['message'] ?? 'You have received a new message.';
      case 'updateMessagePrivate':
        return 'A message was updated.';
      case 'newReactPrivate':
        return 'There is a new reaction on a message.';
      case 'deleteMessagePrivate':
        return 'A message was deleted.';
      case 'newProduct':
        final sellerName = notif['productDetails'] != null && notif['productDetails']['sellerName'] != null
            ? '${notif['productDetails']['sellerName']['firstName']} ${notif['productDetails']['sellerName']['lastName']}'
            : '';
        return 'New product added by $sellerName.';
      case 'updateProduct':
        return 'Product updated: ${notif['productDetails']?['product'] ?? "N/A"}.';
      case 'newShipment':
        final sellerName = notif['shipmentDetails'] != null && notif['shipmentDetails']['sellerName'] != null
            ? '${notif['shipmentDetails']['sellerName']['firstName']} ${notif['shipmentDetails']['sellerName']['lastName']}'
            : "";
        return 'New shipment created by $sellerName for ${notif['shipmentDetails']?['product'] ?? "N/A"}.';
      case 'updateShipment':
        return 'Shipment updated.';
      case 'shipmentStatus':
        return 'Shipment status changed to ${notif['shipmentDetails']?['status'] ?? "N/A"}.';
      case 'shipmentLocation':
        return 'Shipment location updated.';
      case 'newUser':
        final fullName = '${notif['userDetails']?['firstName'] ?? ""} ${notif['userDetails']?['lastName'] ?? ""}'.trim();
        return 'Registered as ${fullName.isNotEmpty ? fullName : "User"}.';
      case 'updateUser':
        return 'User information updated.';
      default:
        return notif['message'] ?? '';
    }
  }

  // Helper: Format timestamp given as an integer (assumed epoch seconds).
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    int ts = timestamp is int ? timestamp : 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final dateString = DateFormat("MMM d, y").format(dt);
    final timeString = DateFormat.jm().format(dt);
    return "$dateString\n$timeString";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationDatabase>(builder: (context, notifDb, child) {
      // Group notifications by day (yyyy-MM-dd).
      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (var notif in notifDb.notifications) {
        if (notif['timestamp'] == null) continue;
        final timestamp = (int.parse(notif['timestamp'].seconds.toString())) * 1000;
        final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final groupKey = DateFormat("MMMM d, y").format(dt);
        groups.putIfAbsent(groupKey, () => []).add(notif);
      }
      // Sort group keys in descending order.
      final sortedKeys = groups.keys.toList()
        ..sort((a, b) {
            final dtA = DateFormat("MMMM d, y").parse(a);
            final dtB = DateFormat("MMMM d, y").parse(b);
          return dtB.compareTo(dtA);
        });

      return Scaffold(
        appBar: AppBar(
          title: const Text("Notifications"),
        ),
        body: groups.isEmpty
        ? const Center(child: Text("No notifications."))
        : ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
          final groupKey = sortedKeys[index];
          final groupNotifs = groups[groupKey]!;
          return ExpansionTile(
            title: Text(groupKey),
            initiallyExpanded: index == 0, // Latest/first group is collapsed.
            children: groupNotifs.map((notif) {
              return ListTile(
            title: Text(getTitle(notif)),
            subtitle: Text(getConcise(notif)),
            trailing: Text(
              formatTimestamp(int.parse(notif['timestamp'].seconds.toString())),
              textAlign: TextAlign.right,
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
              title: Text(getTitle(notif)),
              content: SingleChildScrollView(child: Text(notif['message'] ?? '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
                ),
              );
            },
              );
            }).toList(),
          );
            },
          ),
      );
    });
  }
}