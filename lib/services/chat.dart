

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:harvest_guard/global.dart';


class Chat {
  List<String>? chatMembers;
  String? chatUid;
  String receiver = '';
  String sender = FirebaseAuth.instance.currentUser!.uid;
  List<MapEntry>? messages;
  Map<String, dynamic>? chat;

  Chat ({
    required this.chat, this.chatMembers, this.chatUid
  }) {
    init();
  }

  Future init() async{
    print('chatUid: $chatUid, chatMembers: $chatMembers');
    if (chatUid != null && chatMembers == null) {    
      if (await _initFromUid() == null) {
        await _initNew();
      }
      return this;
    } else if (chatUid == null && chatMembers != null) {
      if (await _initFromMembers() == null) {
        await _initNew();
      }
      return this;
    }

  }

  Future<MapEntry<String, dynamic>?> _initFromUid() async {
    chatMembers = chat![chatUid]['members'].keys.toList();
    receiver = chatMembers!.firstWhere((element) => element != FirebaseAuth.instance.currentUser!.uid);
    messages = chat![chatUid]['messages'].entries.toList();

    if(chat!.keys.contains(chatUid)) {
      print('chatUid: $chatUid, chatMembers: $chatMembers, messages: $messages');
      return MapEntry(chatUid!, chat![chatUid!]);
    }
    return null;
  }

  Future<MapEntry<String, dynamic>?> _initFromMembers() async {
    for (var c in chat!.entries) {
      
      if (c.value['members'].length == chatMembers!.length) {
        List members = c.value['members'].keys.toList();
        // check if contains all members
        if (chatMembers!.every((element) => members.contains(element))) {
          chatUid = c.key;

          return _initFromUid();
        }
      }
    }
    return null;
  }


  Future _initNew() async {
    // check the chat if set of members already exists
    // if exists, return the chatUid
    // if not, create a new chat

    final newRef = FirebaseFirestore.instance
      .collection('chats').doc();
    
    chatUid = newRef.id;

    Map<String, dynamic> usersMap = {};

    for (var member in chatMembers!) {
      if (member != FirebaseAuth.instance.currentUser!.uid) {
        receiver = member;
        // break;
      }

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(member)
          .get()
          .then((DataSnapshot snapshot) {
        if (snapshot.value != null) {
          Map<dynamic, dynamic> snap =
              snapshot.value! as Map<dynamic, dynamic>;

          FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(member)
              .child('chats')
              .get()
              .then((DataSnapshot snapshot) async {
            if (snapshot.value != null) {
              List<dynamic> c = List.from(snapshot.value! as List<dynamic>);
              c.add(chatUid);
              await FirebaseDatabase.instance
                  .ref()
                  .child('users')
                  .child(member)
                  .child('chats')
                  .set(c);
            } else {
              await FirebaseDatabase.instance
                  .ref()
                  .child('users')
                  .child(member)
                  .child('chats')
                  .set([chatUid]);
            }
          });

          usersMap[member] = {
            'name': {
              'firstName': snap['firstName'],
              'middleName': snap['middleName'],
              'lastName': snap['lastName'],
            },
            'thumbProfileImage': snap['thumbProfileImage'],
            'profileImage': snap['profileImage'],
          };
        }
      });
    }

    await newRef.set({
      'info': {
        'name': '',
        'lastMessage': '',
        'lastMessageTime': '',
        'lastMessageSender': '',
        'messageCount': 0,
        'chatInfos': {},
        'members': Map.fromIterable(usersMap.keys, value: (_) => true),    },
      'members': usersMap,
    });

    print('done');
    print('chatMembers: $chatMembers, chatUid: $chatUid');

    // await newRef.collection('messages').doc('custom_id').set({
    //   'message': 'Chat created',
    //   'sender': 'system',
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
    
  }

  Future sendMessage({required String message, dynamic file}) async {
    String epochTime = DateTime.now().millisecondsSinceEpoch.toString();
    final newRef = FirebaseFirestore.instance
      .collection('chats')
      .doc(chatUid!)
      .collection('messages');


    await newRef.doc(epochTime).set({
      'timestamp': epochTime,
      'message': message,
      'sender': FirebaseAuth.instance.currentUser!.uid,
      'file': {
        'url': '',
        'type': '',
      },
    });

    // get count of messages
    await newRef.get().then((QuerySnapshot snapshot) async {
      if (snapshot.size > 0) {
      int count = snapshot.size;
      await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatUid!)
        .update({
          'info.lastMessage': message,
          'info.lastMessageTime': epochTime,
          'info.lastMessageSender': FirebaseAuth.instance.currentUser!.uid,
          'info.messageCount': count,
        });
       }
      }
    );

   
  }

}