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

  bool firstRun = true;
  final FlutterLocalNotificationsPlugin localChatNotif =
      FlutterLocalNotificationsPlugin();

  ChatDatabase() {
    _initializeChatNotifications();
    FirebaseFirestore.instance
        .collection('chats')
        .where('info.members.${FirebaseAuth.instance.currentUser!.uid}', isEqualTo: true)
        .snapshots()
        .listen((event) {
      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added ||
            element.type == DocumentChangeType.modified &&
                !chatEvents.containsKey(element.doc.id)) {

          if (chatsMap[element.doc.id] == null) {
            chatsMap[element.doc.id] = element.doc.data();

            for (var member in element.doc.data()!['info']['members'].keys) {
              if (member != FirebaseAuth.instance.currentUser!.uid) {
                FirebaseDatabase.instance
                    .ref()
                    .child('users')
                    .child(member)
                    .once()
                    .then((value) {
                  Map<dynamic, dynamic> user = value.snapshot.value! as Map<dynamic, dynamic>;
                  chatsMap[element.doc.id]['members'][member] = user;
                  chatsMap[element.doc.id]['members'][member]['name'] =
                    {
                      'firstName': user['firstName'],
                      'middleName': user['middleName'],
                      'lastName': user['lastName'],
                    };
                  notifyListeners();
                });
              }
            }

          } else {
            chatsMap[element.doc.id].addAll(element.doc.data());
          }

          var chatMessages = FirebaseFirestore.instance
              .collection('chats')
              .doc(element.doc.id)
              .collection('messages')
              // .where('sender', isNotEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .snapshots()
              .listen((event) async {
            event.metadata.isFromCache
                ? print('From cache')
                : print('From server');

            print(chatsMap[element.doc.id]['messages'].keys);

            for (var message in event.docChanges) {
              if (message.type == DocumentChangeType.added &&
                  !event.metadata.isFromCache &&
                  message.doc.data()!['sender'] != FirebaseAuth.instance.currentUser!.uid &&
                  chatsMap[element.doc.id].containsKey('messages') &&
                  !chatsMap[element.doc.id]['messages']
                      .containsKey(message.doc.data()!['timestamp'])) {
                FirebaseDatabase.instance
                    .ref()
                    .child('users')
                    .child(message.doc.data()!['sender'])
                    .once()
                    .then((value) {
                  Map<dynamic, dynamic> user =
                      value.snapshot.value! as Map<dynamic, dynamic>;


                  // print('User: ${user['firstName']} ${user['middleName']} ${user['lastName']}');

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

            notifyListeners();
          });

          chatEvents[element.doc.id] = chatMessages;

          if (chatsMap[element.doc.id].containsKey('messages') == false) {
            chatsMap[element.doc.id]!['messages'] = {};
            notifyListeners();
          }
          print("change");
        } else if (element.type == DocumentChangeType.removed &&
          chatEvents.containsKey(element.doc.id)) {
          chatEvents[element.doc.id]!.cancel();
          chatEvents.remove(element.doc.id);
          notifyListeners();
        }
      }
    });
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

  @override
  void dispose() {}
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

            // if (auctionsMap[element.doc.id]['timer'] == null) {
            //   auctionsMap[element.doc.id]['timer'] =
            //       Timer.periodic(const Duration(seconds: 1), (timer) {
            //     var dtS = DateTime.fromMillisecondsSinceEpoch(
            //             1000 * int.parse(element.doc.data()!['epochEnd']))
            //         .difference(DateTime.now());
            //     var dtE = DateTime.fromMillisecondsSinceEpoch(
            //             1000 * int.parse(element.doc.data()!['epochStart']))
            //         .difference(DateTime.now());

            //     if (!dtS.isNegative && dtE.isNegative) {
            //       auctionsMap[element.doc.id]!['status'] = 1;
            //       auctionsMap[element.doc.id]!['statusTime'] = formatTimeRemaining(dtS);
            //     } else if (!dtS.isNegative && !dtE.isNegative) {
            //       auctionsMap[element.doc.id]!['status'] = 0;
            //       auctionsMap[element.doc.id]!['statusTime'] = formatTimeRemaining(dtE);
            //     } else if (dtE.isNegative && dtS.isNegative) {
            //       auctionsMap[element.doc.id]!['status'] = -1;
            //       auctionsMap[element.doc.id]!['statusTime'] = 'Ended';
            //     }

            //     print('Timer: ${dtS.isNegative} ${dtE.isNegative}');
            //     notifyListeners();
            //   });
           
            // }
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
                  auctionsMap[element.doc.id]['bidUid'][bid.doc.id]
                      ['name'] = '${user['firstName']} ${user['middleName']} ${user['lastName']}';
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

  String formatTimeRemaining(Duration duration) {


    String twoDigitMinutes = (duration.inMinutes.remainder(60)).toString();
    String twoDigitSeconds = (duration.inSeconds.remainder(60)).toString();

    if (duration.inDays > 0) {
      return "${duration.inDays}d ${(duration.inHours.remainder(24))}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
    } else if (duration.inHours > 0) {
      return "${(duration.inHours.remainder(24))}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
    } else if (duration.inMinutes > 0) {
      return "${twoDigitMinutes}m ${twoDigitSeconds}s";
    } else {
      return "${twoDigitSeconds}s";
    }
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
      String productName, String adminName) async {
    // generate unique id for notification
    int uid = DateTime.now().millisecondsSinceEpoch;

    await localChatNotif.show(
      // generate uid for notification
      uid,
      'New auction for ${productName.toUpperCase()}',
      'Admin $adminName has created a new auction for $productName. Hurry and check it out!',
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
