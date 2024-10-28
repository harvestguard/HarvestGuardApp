import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/home/chats/chat_bar.dart';

import 'package:harvest_guard/home/chats/chat_widget.dart';
import 'package:harvest_guard/services/chat.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chat});
  final Chat chat;

  @override
  State<ChatPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin<ChatPage> {
  @override
  bool get wantKeepAlive => true;
  String _name = '';
  String _address = '';
  ImageProvider? imageReceiver;
  ImageProvider? imageReceiverBig;
  ImageProvider? imageSender;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();

  late Stream<Map<String, dynamic>> _chats;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _chats = Stream.value(Provider.of<ChatDatabase>(context).chatsMap);
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder(
        stream: _chats,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshots) {
          if (snapshots.data == null ||
              snapshots.data![widget.chat.chatUid] == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          var nameMap = snapshots.data![widget.chat.chatUid]['members']
              [widget.chat.receiver]['name'];
          _name = nameMap != null
              ? '${nameMap['firstName']} ${nameMap['middleName']} ${nameMap['lastName']}'
              : '';

          _address = snapshots.data![widget.chat.chatUid]['members']
              [widget.chat.receiver]['address'];
          
        

          return Scaffold(
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              slivers: [
                ChatAppBar(
                  title: _name,
                  leftIcon: IconButton(
                    icon: const Icon(FluentIcons.arrow_left_24_regular),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  rightIcon: IconButton(
                    icon: const Icon(FluentIcons.info_24_filled),
                    onPressed: () {},
                  ),
                ),

                Builder(builder: (context) {
                  // if (snapshots.connectionState == ConnectionState.waiting) {
                  //   return const SliverFillRemaining(
                  //       child: Center(child: CircularProgressIndicator()));
                  // }

                  if (snapshots.hasError) {
                    return SliverFillRemaining(
                        child:
                            Center(child: Text('Error: ${snapshots.error}')));
                  }

                  imageReceiverBig = snapshots.hasData
                      ? NetworkImage(snapshots.data![widget.chat.chatUid]
                          ['members'][widget.chat.receiver]['profileImage'])
                      : Image.asset('assets/transparent.png').image;
                  imageReceiver = snapshots.hasData
                      ? NetworkImage(snapshots.data![widget.chat.chatUid]
                              ['members'][widget.chat.receiver]
                          ['thumbProfileImage'])
                      : Image.asset('assets/transparent.png').image;

                  var header = Padding(
                    padding: const EdgeInsets.only(
                        left: 30, right: 30, bottom: 50, top: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 100,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                          backgroundImage: imageReceiverBig,
                          child: imageReceiverBig != null
                              ? null
                              : CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Text(_name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                )),
                        Text(_address,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7))),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('View Profile'),
                        ),
                      ],
                    ),
                  );

                  if (!snapshots.hasData) {
                    return SliverToBoxAdapter(
                        child: Center(
                            child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: header,
                    )));
                  }

                  print('Updates');

                  List<MapEntry> entries = snapshots
                      .data![widget.chat.chatUid]['messages'].entries
                      .toList();

                  // sort the entries by timestamp in reverse
                  entries.sort((a, b) {
                    return int.parse(b.value['timestamp'])
                        .compareTo(int.parse(a.value['timestamp']));
                  });

                  Timer(const Duration(milliseconds: 50), () {
                    _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.fastEaseInToSlowEaseOut);
                  });

                  return SliverToBoxAdapter(
                      child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 20),
                          reverse: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entries.length + 1,
                          itemBuilder: (context2, index) {
                            if (index == entries.length) {
                              return header;
                            } else {
                              // entries.sort((a, b) => b.id.compareTo(a.id));
                              final entry = entries[index];

                              var isHiddenTime = false;
                              var isHiddenDate = false;
                              var isCentered = false;

                              if (index != 0) {
                                var entryNext = entries[index - 1];
                                isHiddenTime = entryNext.value['sender'] ==
                                    entry.value['sender'];
                                isHiddenDate = DateTime
                                            .fromMillisecondsSinceEpoch(
                                                int.parse(
                                                    entry.value['timestamp']))
                                        .difference(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(entryNext
                                                    .value['timestamp']))) >
                                    const Duration(days: 1);
                                // print('$isHiddenTime $isHiddenDate $message');
                              }

                              if (index + 1 < entries.length) {
                                var entryPrev = entries[index + 1];
                                isCentered = entryPrev.value['sender'] ==
                                    entry.value['sender'];
                              }

                              final isReceiver = entry.value['sender'] ==
                                  FirebaseAuth.instance.currentUser!.uid;

                              // convert the timestamp to a readable format
                              final timestamp = entry.value['timestamp'];

                              final message = entry.value['message'];
                              final file = entry.value['file'];

                              var chatWidget = ChatWidget(
                                chatUid: widget.chat.chatUid!,
                                message: message,
                                file: '',
                                isReceiver: isReceiver,
                                timestamp: entry.value['timestamp'],
                                imageSender: imageSender ??
                                    Image.asset('assets/transparent.png').image,
                                imageReceiver: imageReceiver ??
                                    Image.asset('assets/transparent.png').image,
                                isHiddenTime: isHiddenTime,
                                isHiddenDate: isHiddenDate,
                                isCentered: isCentered,
                              );

                              if (index == 0 && !isReceiver) {}

                              return chatWidget;
                            }
                          }));
                }),

                // add a fix container on the bottom of the screen
                // to hold the text field and send button
              ],
            ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: EdgeInsets.only(
                    bottom: 15 +
                        (MediaQuery.of(context).viewInsets.bottom >= 100.0
                            ? 0
                            : MediaQuery.of(context).viewPadding.bottom),
                    left: 15,
                    right: 15,
                    top: 15),
                color:
                    Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          contentPadding: const EdgeInsets.all(15),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(0.5),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      padding: const EdgeInsets.all(15),
                      icon: const Icon(FluentIcons.send_24_filled),
                      onPressed: () async {
                        String message = _chatController.text;
                        if (message.isNotEmpty) {
                          // clear the text field
                          _chatController.clear();
                          await widget.chat.sendMessage(message: message);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
