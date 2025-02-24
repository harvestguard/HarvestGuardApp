import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image/image.dart' as img;

enum NotificationChannel {
  chat,
  event,
  reminder,
}

class NotificationDatabase extends ChangeNotifier {
  List<Map<String, dynamic>> notifications = [];
  StreamSubscription? _notificationSubscription;
  final FlutterLocalNotificationsPlugin localNotif =
      FlutterLocalNotificationsPlugin();

  NotificationDatabase() {
    _initLocalNotifications();
    _initializeNotificationsSubscription();
    print('INITIALIZED NOTIFICATION DATABASE');
  }

  Future<void> _initLocalNotifications() async {
    await localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_launcher_monochrome'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  void _initializeNotificationsSubscription() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      // Filter notifications similar to Next.js logic.
      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        if (data['type'] == 'newMessagePrivate' ||
            data['type'] == 'updateMessagePrivate' ||
            data['type'] == 'deleteMessagePrivate') {
          // Ignore notifications originated by current user.
          final from = data['from'];
          if (from is Map && from['uid'] == currentUser.uid) return false;
          final fromUid = from is Map ? from['uid'] : from;
          final to = data['to'];
          final toUid = to is Map ? to['uid'] : to;
          return fromUid == currentUser.uid || toUid == currentUser.uid;
        }
        return true;
      }).toList();

      notifications = filtered.map((doc) => doc.data()).toList();
      notifyListeners();

      print(notifications);

      if (notifications.isNotEmpty) {
        // Sort notifications by timestamp descending.
        notifications.sort((a, b) =>
            (int.parse(b['timestamp'].seconds.toString()))
                .compareTo(int.parse(a['timestamp'].seconds.toString())));
        final latest = notifications.first;
        // Only show a local notification if the sender is not the current user.
        if (latest['sender'] != currentUser.uid) {
          _showLocalNotification(latest);
        }
      }
    });
  }

  Future<void> _showLocalNotification(Map<String, dynamic> notif) async {
    // Map notification type to title and concise message.
    String title = notif['type'] ?? 'Notification';
    String concise = notif['message'] ?? '';

    // Determine if this is a chat notification.
    bool isChatNotification = notif['type'] == 'newMessagePrivate' ||
        notif['type'] == 'updateMessagePrivate' ||
        notif['type'] == 'deleteMessagePrivate';

    if (isChatNotification) {
      final sender = (notif['from'] is Map)
          ? '${notif['from']['name']['firstName']} ${notif['from']['name']['lastName']}'
          : notif['from'];
      title = 'New Message from $sender';
      concise = notif['message'] ?? 'You have received a new message.';
    } else {
      switch (notif['type']) {
        case 'newBid':
          title = 'New Bid';
          concise = 'A new bid has been received.';
          break;
        case 'newAuction':
          title = 'New Auction';
          concise = (notif['auctionDetails'] != null &&
                  notif['auctionDetails']['adminName'] != null)
              ? 'New auction created by ${notif['auctionDetails']['adminName']['firstName']} ${notif['auctionDetails']['adminName']['lastName']}.'
              : 'A new auction has been created.';
          break;
        case 'auctionUpdate':
          title = 'Auction Update';
          concise =
              'Auction updated for product ${notif['auctionDetails']?['product'] ?? "N/A"}.';
          break;
        case 'newReactPrivate':
          title = 'New Reaction';
          concise = 'There is a new reaction on a message.';
          break;
        case 'deleteMessagePrivate':
          title = 'Message Deleted';
          concise = 'A message was deleted.';
          break;
        case "newProduct":
          final sellerName = notif['productDetails']['sellerName'] != null
              ? '${notif['productDetails']['sellerName']['firstName']} ${notif['productDetails']['sellerName']['lastName']}'
              : '';
          concise = 'New product added by $sellerName.';
          title = 'New Product';
          break;
        case "updateProduct":
          concise =
              'Product updated: ${notif['productDetails']['product'] ?? "N/A"}.';
          title = 'Product Update';
          break;
        case "newShipment":
          final sellerName = notif['shipmentDetails']['sellerName'] != null
              ? '${notif['shipmentDetails']['sellerName']['firstName']} ${notif['shipmentDetails']['sellerName']['lastName']}'
              : "";
          concise =
              'New shipment created by $sellerName for ${notif['shipmentDetails']['product'] ?? "N/A"}.';
          title = 'New Shipment';
          break;
        case "updateShipment":
          concise = "Shipment updated.";
          title = "Shipment Update";
          break;
        case "shipmentStatus":
          concise =
              'Shipment status changed to ${notif['shipmentDetails']['status'] ?? "N/A"}.';
          title = "Shipment Status";
          break;
        case "shipmentLocation":
          concise = "Shipment location updated.";
          title = "Shipment Location";
          break;
        case "newUser":
          final fullName =
              '${notif['userDetails']['firstName'] ?? ""} ${notif['userDetails']['middleName'] ?? ""} ${notif['userDetails']['lastName'] ?? ""}'
                  .trim();
          final userType = notif['userDetails']['isSeller'] == true
              ? "Seller"
              : notif['userDetails']['isDeliveryAgent'] == true
                  ? "Delivery Agent"
                  : "User";
          concise = 'Registered as $userType: $fullName.';
          title = "New User";
          break;
        case "updateUser":
          concise = "User information updated.";
          title = "User Update";
          break;
        default:
          concise = notif['message'];
      }
    }

    // Choose channel id and name based on notification type.
    final String channelId =
        isChatNotification ? 'messages_channel' : 'notifications_channel';
    final String channelName =
        isChatNotification ? 'Message Notifications' : 'Notifications';

    AndroidNotificationDetails androidDetails;

    if (isChatNotification) {
      // Use Android's MessagingStyle for conversation notifications.
      final String senderName = (notif['from'] is Map)
          ? '${notif['from']['name']['firstName']} ${notif['from']['name']['lastName']}'
          : notif['from'] ?? 'Unknown';

      // get the image from the database Image.network(notif['from']['thumbProfileImage'])

      final imageThumbUrl = notif['from']['thumbProfileImage'] ?? '';
      final Uri imageUri = Uri.parse(imageThumbUrl);
      final ByteData imageData = await NetworkAssetBundle(imageUri).load("");
      final Uint8List originalBytes = imageData.buffer.asUint8List();

      // Decode the image using the image package.
      final img.Image? originalImage = img.decodeImage(originalBytes);
      Uint8List imageBytes;
      if (originalImage != null) {
        // Crop the image to a square.
        int size = originalImage.width < originalImage.height
            ? originalImage.width
            : originalImage.height;
        final img.Image squareImage =
            img.copyResizeCropSquare(originalImage, size: size);

        // Create a circular crop by applying a circular mask.
        final img.Image circularImage = img.Image(width: size, height: size);
        int center = size ~/ 2;
        double radius = size / 2;
        for (int y = 0; y < size; y++) {
          for (int x = 0; x < size; x++) {
            final dx = x - center;
            final dy = y - center;
            if (sqrt(dx * dx + dy * dy) <= radius) {
              circularImage.setPixel(x, y, squareImage.getPixel(x, y));
            } else {
              circularImage.setPixel(x, y, img.ColorFloat16.rgba(0, 0, 0, 0));
            }
          }
        }
        imageBytes = Uint8List.fromList(img.encodePng(circularImage));
      } else {
        imageBytes = originalBytes;
      }

      final person =
          Person(name: senderName, icon: ByteArrayAndroidIcon(imageBytes));
      androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Chat messages',
        importance: Importance.max,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: false,
        icon: '@drawable/ic_launcher_monochrome',
        styleInformation: MessagingStyleInformation(
          person,
          groupConversation: true,
          messages: [
            Message(
              concise,
              DateTime.now(),
              person,
            )
          ],
        ),
      );
    } else {
      // Use normal notification style.
      androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        icon: '@drawable/ic_launcher_monochrome',
        channelDescription: 'General notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: false,
      );
    }

    await localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      concise,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  @override
  void dispose() {
    // _notificationSubscription?.cancel();
    // super.dispose();
  }

  void forceDispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

class ChatDatabase extends ChangeNotifier {
  Map<String, StreamSubscription> chatEvents = {};
  Map<String, dynamic> chatsMap = {};
  final bool _disposed = false;
  StreamSubscription? _mainSubscription;

  ChatDatabase() {
    _initializeMainSubscription();
    print('INITIALIZED CHAT DATABASE');
  }

  void _initializeMainSubscription() {
    _mainSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('info.members.${FirebaseAuth.instance.currentUser!.uid}',
            isEqualTo: true)
        .snapshots()
        .listen((event) {
      print(event.docs);
      if (_disposed) return; // Skip if disposed
      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added ||
            (element.type == DocumentChangeType.modified &&
                !chatEvents.containsKey(element.doc.id))) {
          if (chatsMap[element.doc.id] == null) {
            chatsMap[element.doc.id] = element.doc.data();
            for (var member in element.doc.data()!['info']['members'].keys) {
              if (_disposed) return; // Skip if disposed during async operation
              FirebaseDatabase.instance
                  .ref()
                  .child('users')
                  .child(member)
                  .once()
                  .then((value) {
                if (_disposed) {
                  return; // Skip if disposed during async operation
                }
                Map<dynamic, dynamic> user =
                    value.snapshot.value! as Map<dynamic, dynamic>;
                chatsMap[element.doc.id]['members'][member] = user;
                chatsMap[element.doc.id]['members'][member]['name'] = {
                  'firstName': user['firstName'],
                  'middleName': user['middleName'],
                  'lastName': user['lastName'],
                };
                safeNotifyListeners();
              });
            }
          } else {
            chatsMap[element.doc.id].addAll(element.doc.data());
          }

          // Removed chat message local notification logic.
          var chatMessages = FirebaseFirestore.instance
              .collection('chats')
              .doc(element.doc.id)
              .collection('messages')
              .snapshots()
              .listen((event) async {
            if (_disposed) return; // Skip if disposed
            event.metadata.isFromCache
                ? print('From cache')
                : print('From server');
            print(chatsMap[element.doc.id]['messages'].keys);

            for (var message in event.docChanges) {
              if (_disposed) break; // Break loop if disposed

              if (message.type == DocumentChangeType.added ||
                  message.type == DocumentChangeType.modified) {
                chatsMap[element.doc.id]!['messages'][message.doc.id] =
                    message.doc.data() as Map<String, dynamic>;
              } else if (message.type == DocumentChangeType.removed) {
                chatsMap[element.doc.id]!['messages'].remove(message.doc.id);
              }
            }
            safeNotifyListeners();
          });
          chatEvents[element.doc.id] = chatMessages;
          if (chatsMap[element.doc.id].containsKey('messages') == false) {
            chatsMap[element.doc.id]!['messages'] = {};
            safeNotifyListeners();
          }
          print("change");
        } else if (element.type == DocumentChangeType.removed &&
            chatEvents.containsKey(element.doc.id)) {
          chatEvents[element.doc.id]!.cancel();
          chatEvents.remove(element.doc.id);
          safeNotifyListeners();
        }
      }
    });
  }

  // Safe way to notify listeners that checks disposal state
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void updateData() {
    print('UPDATED USER INFO');
    safeNotifyListeners();
  }

  @override
  void dispose() {
    // _mainSubscription?.cancel();
    // super.dispose();
  }

  void forceDispose() {
    _mainSubscription?.cancel();
    super.dispose();
  }
}

class AuctionDatabase extends ChangeNotifier {
  Map<String, StreamSubscription> auctionEvents = {};
  Map<String, dynamic> auctionsMap = {};
  bool firstRun = true;

  AuctionDatabase() {
    FirebaseFirestore.instance
        .collection('auctions')
        .snapshots()
        .listen((event) {
      for (var element in event.docChanges) {
        print(
            'list: ${element.type} ${auctionEvents.containsKey(element.doc.id)}');
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified) {
          if (!auctionEvents.containsKey(element.doc.id)) {
            auctionsMap[element.doc.id] = element.doc.data();
          } else {
            auctionsMap[element.doc.id].addAll(element.doc.data());
          }
          FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(auctionsMap[element.doc.id]['adminUid'])
              .once()
              .then((value) {
            Map<dynamic, dynamic> user =
                value.snapshot.value! as Map<dynamic, dynamic>;
            print('ff, list: $user');
            auctionsMap[element.doc.id]['adminInfo'] = user;
            notifyListeners();
          });
          FirebaseFirestore.instance
              .collection('products')
              .doc(auctionsMap[element.doc.id]['adminUid'])
              .collection('items')
              .doc(auctionsMap[element.doc.id]['productUid'])
              .get()
              .then((value) {
            Map<String, dynamic> product = value.data()!;
            auctionsMap[element.doc.id]['itemInfo'] = product;
            // Removed new auction notification logic.
          });
          var auctionBidMessages = FirebaseFirestore.instance
              .collection('auctions')
              .doc(element.doc.id)
              .collection('bidUid')
              .snapshots()
              .listen((event) async {
            event.metadata.isFromCache
                ? print('From cache')
                : print('From server');
            for (var bid in event.docChanges) {
              if (bid.type == DocumentChangeType.added ||
                  bid.type == DocumentChangeType.modified) {
                FirebaseDatabase.instance
                    .ref()
                    .child('users')
                    .child(bid.doc.data()!['userUid'])
                    .once()
                    .then((value) {
                  Map<dynamic, dynamic> user =
                      value.snapshot.value! as Map<dynamic, dynamic>;
                  auctionsMap[element.doc.id]['bidUid'][bid.doc.id]
                      ['thumbProfileImage'] = user['thumbProfileImage'];
                  auctionsMap[element.doc.id]['bidUid'][bid.doc.id]['name'] =
                      '${user['firstName']} ${user['middleName']} ${user['lastName']}';
                  Future.delayed(const Duration(milliseconds: 250), () {
                    notifyListeners();
                  });
                  // Removed new bid notification logic.
                });
                auctionsMap[element.doc.id]!['bidUid'][bid.doc.id] =
                    bid.doc.data() as Map<String, dynamic>;
              } else if (bid.type == DocumentChangeType.removed) {
                auctionsMap[element.doc.id]!['bidUid'].remove(bid.doc.id);
                notifyListeners();
              }
            }
          });
          auctionEvents[element.doc.id] = auctionBidMessages;
          if (auctionsMap[element.doc.id].containsKey('bidUid') == false) {
            auctionsMap[element.doc.id]!['bidUid'] = {};
            notifyListeners();
          }
        } else if (element.type == DocumentChangeType.removed &&
            auctionEvents.containsKey(element.doc.id)) {
          auctionEvents[element.doc.id]!.cancel();
          auctionEvents.remove(element.doc.id);
          notifyListeners();
        }
      }
    });
    print('INITIALIZED AUCTION DATABASE');
  }

  void updateData() {
    notifyListeners();
  }

  @override
  void dispose() {
    // for (var sub in auctionEvents.values) {
    //   sub.cancel();
    // }
    // super.dispose();
  }

  void forceDispose() {
    for (var sub in auctionEvents.values) {
      sub.cancel();
    }
    super.dispose();
  }
}

class ShipmentDatabase extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _shipments = {};
  Map<String, Map<String, dynamic>> get shipments => _shipments;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription<QuerySnapshot>? _shipmentsSubscription;

  ShipmentDatabase() {
    _setupShipmentsListener();
    print('INITIALIZED SHIPMENT DATABASE');
  }

  void _setupShipmentsListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _shipmentsSubscription?.cancel();
    _shipmentsSubscription = FirebaseFirestore.instance
        .collection('shipments')
        .where(Filter('buyerUid', isEqualTo: user.uid))
        .snapshots()
        .listen((snapshot) {
      _handleShipmentChanges(snapshot);
    });
  }

  Future<void> _handleShipmentChanges(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      switch (change.type) {
        case DocumentChangeType.added:
          await _handleNewShipment(change.doc);
          break;
        case DocumentChangeType.modified:
          await _handleModifiedShipment(change.doc);
          break;
        case DocumentChangeType.removed:
          _handleRemovedShipment(change.doc);
          break;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _handleNewShipment(DocumentSnapshot doc) async {
    final shipData = doc.data() as Map<String, dynamic>;
    await _processShipmentDocument(doc.id, shipData);
  }

  Future<void> _handleModifiedShipment(DocumentSnapshot doc) async {
    final newData = doc.data() as Map<String, dynamic>;
    final oldData =
        _shipments[doc.id]?['shippingInfo'] as Map<String, dynamic>?;
    if (oldData != null) {
      final oldStatus =
          _getLatestStatus(oldData['status'] as Map<String, dynamic>?);
      final newStatus =
          _getLatestStatus(newData['status'] as Map<String, dynamic>?);
      if (oldStatus != newStatus) {
        await _processShipmentDocument(doc.id, newData);
      }
    }
  }

  void _handleRemovedShipment(DocumentSnapshot doc) {
    _shipments.remove(doc.id);
    notifyListeners();
  }

  String _getLatestStatus(Map<String, dynamic>? statusMap) {
    if (statusMap == null || statusMap.isEmpty) return 'Pending';
    final latestEpoch = statusMap.keys
        .map((e) => int.tryParse(e) ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return statusMap[latestEpoch.toString()] ?? 'Pending';
  }

  Future<void> _processShipmentDocument(
      String docId, Map<String, dynamic> shipData) async {
    try {
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('products')
            .doc(shipData['sellerUid'])
            .collection('items')
            .doc(shipData['productUid'])
            .get(),
        FirebaseDatabase.instance
            .ref()
            .child('users/${shipData['buyerUid']}')
            .get(),
        FirebaseFirestore.instance
            .collection('auctions')
            .doc(shipData['auctionId'])
            .get(),
      ]);

      final productDoc = futures[0] as DocumentSnapshot;
      final buyerSnapshot = futures[1] as DataSnapshot;
      final auctionDoc = futures[2] as DocumentSnapshot;

      final Map<String, dynamic> buyerData =
          Map<String, dynamic>.from(buyerSnapshot.value as Map? ?? {});
      final Map<String, dynamic> productData = Map<String, dynamic>.from(
          productDoc.data() as Map<String, dynamic>? ?? {});
      final Map<String, dynamic> auctionData = Map<String, dynamic>.from(
          auctionDoc.data() as Map<String, dynamic>? ?? {});

      auctionData['buyerName'] =
          '${buyerData['firstName']} ${buyerData['middleName']} ${buyerData['lastName']}';
      auctionData['buyerAddress'] = buyerData['address'];
      auctionData['buyerContact'] = buyerData['number'];

      _shipments[docId] = {
        'buyerInfo': buyerData,
        'productInfo': productData,
        'shippingInfo': shipData,
        'auctionInfo': auctionData,
      };

      notifyListeners();
    } catch (error) {
      debugPrint('Error processing shipment document: $error');
    }
  }

  @override
  void dispose() {
    // _shipmentsSubscription?.cancel();
    // super.dispose();
  }

  void forceDispose() {
    _shipmentsSubscription?.cancel();
    super.dispose();
  }
}
