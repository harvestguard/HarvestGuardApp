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
    // Define reply action for messaging notifications
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        localNotif.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'messages_channel',
        'Message Notifications',
        description: 'Chat messages',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        playSound: true,
      ),
    );

    // Register for reply intents
    const String replyActionId = 'REPLY_ACTION';
    
    // Initialize notifications with action handlers
    await localNotif.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@drawable/ic_launcher_monochrome'),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.notificationResponseType == NotificationResponseType.selectedNotificationAction &&
            response.actionId == replyActionId) {
          // Handle the reply text
          final replyText = response.input;
          if (replyText != null && replyText.isNotEmpty) {
            // Here you would implement your reply logic
            print('User replied: $replyText');
            // sendReply(response.payload, replyText);
          }
        }
      },
    );
  }

  // Store the last notification ID to prevent repeats
  static String? _lastNotificationId;
  // Store conversation data for People API
  final Map<String, List<Message>> _conversations = {};
  final Map<String, Person> _people = {};

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

      if (notifications.isNotEmpty) {
        // Sort notifications by timestamp descending
        notifications.sort((a, b) =>
            (int.parse(b['timestamp'].seconds.toString()))
                .compareTo(int.parse(a['timestamp'].seconds.toString())));

        final latest = notifications.first;
        final notificationId =
            latest['id'] ?? '${latest['timestamp'].seconds}_${latest['type']}';

        // Only show notification if:
        // 1. It's not from the current user
        // 2. It hasn't been shown before (different ID from last notification)
        if (latest['sender'] != currentUser.uid &&
            notificationId != _lastNotificationId) {
          _lastNotificationId = notificationId;
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
      await _showChatNotification(notif);
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

      // Use normal notification style for non-chat notifications
      final androidDetails = AndroidNotificationDetails(
        'notifications_channel',
        'Notifications',
        icon: '@drawable/ic_launcher_monochrome',
        channelDescription: 'General notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: true,
      );

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
  }

  Future<void> _showChatNotification(Map<String, dynamic> notif) async {
    if (notif['from'] == null) return;
    
    // Extract conversation ID - could be a chat ID or a combination of users
    final String conversationId = notif['chatId'] ?? 
                                 '${notif['from']['uid']}_${notif['to']['uid']}';
    
    // Get or create sender Person object
    final senderName = (notif['from'] is Map)
        ? '${notif['from']['name']['firstName']} ${notif['from']['name']['lastName']}'
        : notif['from']['name'] ?? 'Unknown';
    
    final String senderId = notif['from']['uid'] ?? 
                           (notif['from'] is Map ? notif['from']['uid'] : notif['from']);
    
    // Get sender profile image for the Person
    Person sender;
    if (!_people.containsKey(senderId)) {
      // Try to get profile image
      try {
        final imageThumbUrl = notif['from']['thumbProfileImage'] ?? '';
        if (imageThumbUrl.isNotEmpty) {
          final Uri imageUri = Uri.parse(imageThumbUrl);
          final ByteData imageData = await NetworkAssetBundle(imageUri).load("");
          final Uint8List originalBytes = imageData.buffer.asUint8List();
          
          // Process the image to make it circular
          final img.Image? originalImage = img.decodeImage(originalBytes);
          if (originalImage != null) {
            final int size = min(originalImage.width, originalImage.height);
            final img.Image circularImage = _createCircularImage(originalImage, size);
            final Uint8List imageBytes = Uint8List.fromList(img.encodePng(circularImage));
            
            sender = Person(
              name: senderName, 
              key: senderId,
              icon: ByteArrayAndroidIcon(imageBytes),
              important: true,
            );
          } else {
            sender = Person(name: senderName, key: senderId, important: true);
          }
        } else {
          sender = Person(name: senderName, key: senderId, important: true);
        }
      } catch (e) {
        sender = Person(name: senderName, key: senderId, important: true);
        print('Error processing profile image: $e');
      }
      
      _people[senderId] = sender;
    } else {
      sender = _people[senderId]!;
    }
    
    // Initialize conversation if it doesn't exist
    if (!_conversations.containsKey(conversationId)) {
      _conversations[conversationId] = [];
    }
    
    // Create the message
    final message = Message(
      notif['message'] ?? 'New message',
      DateTime.fromMillisecondsSinceEpoch((notif['timestamp']?.seconds ?? 0) * 1000),
      sender,
    );
    
    // Add to conversation history (limit to last 10 messages)
    _conversations[conversationId]!.add(message);
    if (_conversations[conversationId]!.length > 10) {
      _conversations[conversationId]!.removeAt(0);
    }
    
    // Create RemoteInput for direct reply capability
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        'REPLY_ACTION',
        'Reply',
        icon: DrawableResourceAndroidBitmap('@android:drawable/ic_menu_send'),
        inputs: [
          AndroidNotificationActionInput(
            allowFreeFormInput: true,
            choices: [],
            label: 'Reply',
          ),
        ],
        contextual: true,
        allowGeneratedReplies: true,
      ),
    ];

    // Show the notification using Messaging style
    final androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Message Notifications',
      channelDescription: 'Chat messages',
      category: AndroidNotificationCategory.message,
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      showWhen: true,
      actions: actions,
      icon: '@drawable/ic_launcher_monochrome',
      styleInformation: MessagingStyleInformation(
        Person(name: 'You', key: FirebaseAuth.instance.currentUser?.uid ?? 'user'),
        conversationTitle: notif['chatName'] ?? senderName,
        groupConversation: notif['isGroup'] ?? false,
        messages: _conversations[conversationId]!,
      ),
    );

    await localNotif.show(
      senderId.hashCode, // Use a consistent ID for the same sender
      senderName,
      notif['message'] ?? 'New message',
      NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'message',
          threadIdentifier: conversationId,
        ),
      ),
      payload: conversationId, // Pass conversation ID for handling replies
    );
  }
  
  // Helper method to create circular profile images
  img.Image _createCircularImage(img.Image original, int size) {
    // Crop to square first
    final img.Image squareImage = img.copyResizeCropSquare(original, size: size);
    
    // Create circular mask
    final img.Image circularImage = img.Image(width: size, height: size);
    final int center = size ~/ 2;
    final double radius = size / 2;
    
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
    
    return circularImage;
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
    debugPrint('INITIALIZED CHAT DATABASE');
  }

  void _initializeMainSubscription() {
    _mainSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('info.members.${FirebaseAuth.instance.currentUser!.uid}',
            isEqualTo: true)
        .snapshots()
        .listen((event) {
      debugPrint('Chat documents: ${event.docs.length}');
      if (_disposed) return; // Skip if disposed
      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added ||
            (element.type == DocumentChangeType.modified &&
                !chatEvents.containsKey(element.doc.id))) {
          if (chatsMap[element.doc.id] == null) {
            // Initialize the chat entry with proper structure
            final chatData = element.doc.data() ?? {};
            chatsMap[element.doc.id] = chatData;
            
            // Ensure messages map exists
            if (!chatsMap[element.doc.id].containsKey('messages')) {
              chatsMap[element.doc.id]['messages'] = {};
            }
            
            // Ensure members map exists
            if (!chatsMap[element.doc.id].containsKey('members')) {
              chatsMap[element.doc.id]['members'] = {};
            }
            
            // Process each member's info
            if (chatData['info'] != null && 
                chatData['info']['members'] != null) {
              for (var member in chatData['info']['members'].keys) {
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
                  if (value.snapshot.value != null) {
                    Map<dynamic, dynamic> user =
                        value.snapshot.value! as Map<dynamic, dynamic>;
                    chatsMap[element.doc.id]['members'][member] = user;
                    chatsMap[element.doc.id]['members'][member]['name'] = {
                      'firstName': user['firstName'],
                      'middleName': user['middleName'],
                      'lastName': user['lastName'],
                    };
                    safeNotifyListeners();
                  }
                });
              }
            }
          } else {
            // Update existing chat data
            chatsMap[element.doc.id].addAll(element.doc.data() ?? {});
          }

          // Setup messages listener
          var chatMessages = FirebaseFirestore.instance
              .collection('chats')
              .doc(element.doc.id)
              .collection('messages')
              .snapshots()
              .listen((event) async {
            if (_disposed) return; // Skip if disposed
            debugPrint('Message data source: ${event.metadata.isFromCache ? 'cache' : 'server'}');
            
            // Ensure messages map exists
            if (!chatsMap[element.doc.id].containsKey('messages')) {
              chatsMap[element.doc.id]['messages'] = {};
            }
            
            debugPrint('Messages count: ${chatsMap[element.doc.id]['messages'].keys.length}');

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
          debugPrint("Chat structure updated: ${element.doc.id}");
        } else if (element.type == DocumentChangeType.removed &&
            chatEvents.containsKey(element.doc.id)) {
          chatEvents[element.doc.id]!.cancel();
          chatEvents.remove(element.doc.id);
          chatsMap.remove(element.doc.id);
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
    debugPrint('UPDATED USER INFO');
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
