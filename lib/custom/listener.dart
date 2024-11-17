import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/home/auctions/auction_page.dart';
import 'package:harvest_guard/home/chats/chats_page.dart';
import 'package:harvest_guard/services/chat.dart';

enum NotificationChannel {
  chat,
  event,
  reminder,
}

class ChatDatabase extends ChangeNotifier {
  Map<String, StreamSubscription> chatEvents = {};
  Map<String, dynamic> chatsMap = {};
  final bool _disposed = false;
  StreamSubscription? _mainSubscription;

  bool firstRun = true;
  final FlutterLocalNotificationsPlugin localChatNotif =
      FlutterLocalNotificationsPlugin();

  ChatDatabase() {
    _initializeChatNotifications();
    _initializeMainSubscription();
  }

  void _initializeChatNotifications() async {
    await localChatNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == 'reply') {
          Chat(chat: chatsMap, chatUid: response.payload)
              .sendMessage(message: response.input ?? '');
        } else {
          navigatorKeyMain.currentState!.popAndPushNamed(
            '/chat',
            arguments: {
              'chat': Chat(chat: chatsMap, chatUid: response.payload),
              'from': navigatorKeyMain.currentState!.context
                  .findAncestorWidgetOfExactType<ChatsPage>()!,
            },
          );
        }

        await localChatNotif.cancel(response.id!);
      },
    );
  }

  void _initializeMainSubscription() {
    _mainSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('info.members.${FirebaseAuth.instance.currentUser!.uid}',
            isEqualTo: true)
        .snapshots()
        .listen((event) {

      print( event.docs);


      if (_disposed) return; // Skip if disposed

      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified &&
                !chatEvents.containsKey(element.doc.id)) {
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

              if (message.type == DocumentChangeType.added &&
                  !event.metadata.isFromCache &&
                  message.doc.data()!['sender'] !=
                      FirebaseAuth.instance.currentUser!.uid &&
                  chatsMap[element.doc.id].containsKey('messages') &&
                  !chatsMap[element.doc.id]['messages']
                      .containsKey(message.doc.data()!['timestamp'])) {
                FirebaseDatabase.instance
                    .ref()
                    .child('users')
                    .child(message.doc.data()!['sender'])
                    .once()
                    .then((value) {
                  if (_disposed) return; // Skip if disposed

                  Map<dynamic, dynamic> user =
                      value.snapshot.value! as Map<dynamic, dynamic>;

                  _showChatNotification(
                    element.doc.id,
                    '${user['firstName']} ${user['middleName']} ${user['lastName']}',
                    message.doc.data()!['message'],
                    message.doc.id,
                    user['thumbProfileImage'],
                    'Messages',
                    'New messages from your chats',
                  );
                });
              }

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
   
  }

  Future<void> _showChatNotification(
      String chatId,
      String title,
      String body,
      String messageId,
      String icon,
      String channelName,
      String channelDescription) async {
    // print('Chat ID: $chatId, Message ID: $messageId');

    await localChatNotif.show(
      ((int.tryParse(messageId) ?? 0) / 1000).round(),
      title,
      body,
      NotificationDetails(
          android: AndroidNotificationDetails(
        chatId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: false,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'reply',
            'Reply',
            showsUserInterface: true,
            allowGeneratedReplies: true,
            inputs: <AndroidNotificationActionInput>[
              AndroidNotificationActionInput(
                label: 'Reply here...',
              ),
            ],
          ),
        ],
      )),
      payload: chatId,
    );
  }
  // Rest of the code remains the same...
  // (_initializeChatNotifications and _showChatNotification methods)
}

class AuctionDatabase extends ChangeNotifier {
  Map<String, StreamSubscription> auctionEvents = {};
  Map<String, dynamic> auctionsMap = {};

  bool firstRun = true;
  final FlutterLocalNotificationsPlugin localChatNotif =
      FlutterLocalNotificationsPlugin();

  AuctionDatabase() {
    _initializeAuctionNotifications();
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

            if (element.type == DocumentChangeType.added &&
                !event.metadata.isFromCache) {
              _showNewAuctionNotification(
                auctionsMap[element.doc.id]['itemInfo']['item'],
                auctionsMap[element.doc.id]['itemInfo']['adminUid'],
              );
            }
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

            // print('1, list: ${element.doc.data()} ${event.docChanges.length}');

            for (var bid in event.docChanges) {
              // print('2, list: ${bid.doc.data()}');
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
                  // add 250 ms delay to allow the user to be added to the map

                  Future.delayed(const Duration(milliseconds: 250), () {
                    notifyListeners();
                  });

                  // print('2.5, list: ${auctionsMap}');

                  if (!event.metadata.isFromCache &&
                      bid.type == DocumentChangeType.added) {
                    _showNewBidNotification(
                      auctionsMap[element.doc.id]['itemInfo']['item'],
                      '${user['firstName']} ${user['middleName']} ${user['lastName']}',
                    );
                  }
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
  }

  void updateData() {
    notifyListeners();
  }

  void _initializeAuctionNotifications() async {
    await localChatNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) async {
        navigatorKeyMain.currentState!.popAndPushNamed(
          '/auction',
          arguments: {
            'auctionMap': auctionsMap,
            'auctionUid': response.payload,
            'from': navigatorKeyMain.currentState!.context
                .findAncestorWidgetOfExactType<AuctionPage>()!,
          },
        );

        await localChatNotif.cancel(response.id!);
      },
    );
  }

  Future<void> _showNewBidNotification(
      String productName, String newUserBidName) async {
    // generate unique id for notification
    int uid = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    await localChatNotif.show(
      // generate uid for notification
      uid,
      'New bidding for ${productName.toUpperCase()}',
      'User $newUserBidName has placed a new bid on $productName. Hurry and check it out!',
      NotificationDetails(
          android: AndroidNotificationDetails(
        uid.toString(),
        'Auctions Bid',
        channelDescription: 'New bids from your auctions',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: false,
      )),
      payload: uid.toString(),
    );
  }

  Future<void> _showNewAuctionNotification(
      String productName, String sellerName) async {
    // generate unique id for notification
    int uid = DateTime.now().millisecondsSinceEpoch;

    await localChatNotif.show(
      // generate uid for notification
      uid,
      'New auction for ${productName.toUpperCase()}',
      'Seller $sellerName has created a new auction for $productName. Hurry and check it out!',
      NotificationDetails(
          android: AndroidNotificationDetails(
        uid.toString(),
        'Auctions',
        channelDescription: 'New auctions available',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: false,
      )),
      payload: uid.toString(),
    );
  }

  @override
  void dispose() {}
}

class ShipmentDatabase extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _shipments = {};
  Map<String, Map<String, dynamic>> get shipments => _shipments;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  StreamSubscription<QuerySnapshot>? _shipmentsSubscription;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  ShipmentDatabase() {
    _initNotifications();
    _setupShipmentsListener();
  }

  Future<void> _initNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications.initialize(initializationSettings);
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
    _showNotification(
      'New Shipment',
      'A new shipment has been created for ${_shipments[doc.id]?['productInfo']?['name'] ?? 'Unknown Product'}',
    );
  }

  Future<void> _handleModifiedShipment(DocumentSnapshot doc) async {
    final newData = doc.data() as Map<String, dynamic>;
    final oldData = _shipments[doc.id]?['shippingInfo'] as Map<String, dynamic>?;
    
    if (oldData != null) {
      final oldStatus = _getLatestStatus(oldData['status'] as Map<String, dynamic>?);
      final newStatus = _getLatestStatus(newData['status'] as Map<String, dynamic>?);
      
      if (oldStatus != newStatus) {
        await _processShipmentDocument(doc.id, newData);
        _showNotification(
          'Shipment Status Updated',
          'Status changed to: $newStatus',
        );
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

  Future<void> _processShipmentDocument(String docId, Map<String, dynamic> shipData) async {
    try {
      // Fetch product, buyer, and auction data concurrently
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
      final Map<String, dynamic> productData = 
          Map<String, dynamic>.from(productDoc.data() as Map<String, dynamic>? ?? {});
      final Map<String, dynamic> auctionData = 
          Map<String, dynamic>.from(auctionDoc.data() as Map<String, dynamic>? ?? {});


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

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'shipments_channel',
      'Shipments',
      channelDescription: 'Notifications for shipment updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  @override
  void dispose() {
  }
}