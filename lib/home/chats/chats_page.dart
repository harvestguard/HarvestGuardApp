import 'dart:async';

import 'package:animated_list_plus/transitions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/home/app_bar.dart';
import 'package:harvest_guard/services/chat.dart';
import 'package:harvest_guard/services/tools.dart';
import 'package:provider/provider.dart';
import 'package:animated_list_plus/animated_list_plus.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({required this.navigatorKey, required super.key});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<ChatsPage> createState() => _membersPageState();
}

class _membersPageState extends State<ChatsPage>
    with AutomaticKeepAliveClientMixin<ChatsPage> {
  @override
  bool get wantKeepAlive => true;
  List<SearchInfo> searchInfos = <SearchInfo>[];
  List<ChatInfo> chatInfos = <ChatInfo>[];

  // late Stream<QuerySnapshot<Map<String, dynamic>>> _members;
  late Stream<Map<String, dynamic>> _chats;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _chats = Stream.value(context.watch<ChatDatabase>().chatsMap);
  }

  Future _loadSearchChats() async {
    // find the ChatDatabase in higher hierarchy

    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .get()
        .then((DataSnapshot snapshot) async {
      if (snapshot.value != null) {
        // check if the current user is in the list of users
        if (snapshot.key == FirebaseAuth.instance.currentUser!.uid) {
          return;
        }

        final Map<dynamic, dynamic> users =
            snapshot.value! as Map<dynamic, dynamic>;
        searchInfos.clear();
        users.forEach((key, value) {
          setState(() {
            searchInfos.add(SearchInfo(
              uid: key,
              name:
                  '${value['firstName']} ${value['middleName']} ${value['lastName']}',
              thumbProfileImage: value['thumbProfileImage'],
            ));
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var noMessage = SliverFillRemaining(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/no_messages.png',
            width: 150,
            height: 150,
            color:
                Theme.of(context).colorScheme.outlineVariant, // Add tint color
          ),
          const SizedBox(height: 20),
          Text('YOU HAVE NO MESSAGES',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )),
          Text('Start a new conversation by clicking the button below',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7))),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // handle new conversation button press
              // Chat(chatMembers: [
              //   '4qPzatjgipbzpjmohmnAZq9gexk1',
              //   'VvaV9n2PNNT1iEQMONV76Smsgh73'
              // ]);
            },
            child: const Text('New Conversation'),
          ),
        ],
      ),
    ));

    return Scaffold(
      body: CustomScrollView(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        slivers: [
          HomeAppBar(
            title: 'Chats',
            leftIcon: IconButton(
              icon: const Icon(FluentIcons.list_24_filled),
              onPressed: () {
                scaffoldKey.currentState!.openDrawer();
              },
            ),
            rightIcon: IconButton(
              icon: const Icon(FluentIcons.person_24_regular),
              onPressed: () {
                // FirebaseFirestore.instance
                //     .collection('chats')
                //     .doc('bPHtSNBvEPL5UM0QRLmr')
                //     .get()
                //     .then((value) => print(value.data()));
              },
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SearchChatsHeaderDelegate(
              searchInfo: searchInfos,
              databaseName: 'chatSearchHistory',
              barHintText: 'Search chats',
              cont: context,
              onTap: () {
                _loadSearchChats();
              },
            ),
          ),
          StreamBuilder(
            stream: _chats,
            builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
              if (snapshot.hasError) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('An error occurred'),
                  ),
                );
              } else if (snapshot.hasData) {
                final List<ChatInfo> docs = snapshot.data!
                    .map((key, value) =>
                        MapEntry(key, ChatInfo.fromMap(key, value)))
                    .values
                    .toList();

                // remove to the list those chatInfo time is null
                docs.removeWhere((element) => element.lastMessageTime.isEmpty);

                docs.sort((a, b) {
                  return b.lastMessageTime.compareTo(a.lastMessageTime);
                });
                if (docs.isEmpty) {
                  return noMessage;
                }

                return SliverToBoxAdapter(
                  child: ImplicitlyAnimatedList<ChatInfo>(
                    items: docs,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    areItemsTheSame: (a, b) => a.uid == b.uid,
                    itemBuilder: (context, animation, chatInfo, index) {
                      return SizeFadeTransition(
                        sizeFraction: 0.7,
                        curve: Curves.easeInOut,
                        animation: animation,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(chatInfo.thumbProfileImage),
                            radius: 25,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chatInfo.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Text(
                                parseDate(chatInfo.lastMessageTime),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  fontSize: 13.0,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            chatInfo.lastMessage.replaceAll('\n', ' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/chat',
                              arguments: {
                                'chat': Chat(
                                    chat: snapshot.data!,
                                    chatUid: docs[index].uid),
                                'from': context.findAncestorWidgetOfExactType<
                                    ChatsPage>()!,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              }
              return const SliverFillRemaining(
                child: Center(
                  child: Text('An error occurred'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
