import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harvest_guard/custom/carousel.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/global.dart';

import 'package:harvest_guard/services/chat.dart';
import 'package:harvest_guard/services/countdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AuctionPage extends StatefulWidget {
  const AuctionPage({super.key, required this.auctionUid});
  final String auctionUid;

  @override
  State<AuctionPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<AuctionPage>
    with AutomaticKeepAliveClientMixin<AuctionPage> {
  @override
  bool get wantKeepAlive => true;

  final _isAppBarCollapsed = ValueNotifier<bool>(false);
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _bidController = TextEditingController();

  late Stream<Map<String, dynamic>> _auctions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _auctions = Stream.value(context.watch<AuctionDatabase>().auctionsMap);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    bool isCollapsed = _scrollController.hasClients &&
        _scrollController.offset > (300 - 10 - kToolbarHeight);
    if (isCollapsed != _isAppBarCollapsed) {
      _isAppBarCollapsed.value =
          isCollapsed; // This will trigger rebuiding the text widget.
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: StreamBuilder(
        stream: _auctions,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasError) {
            return const SliverFillRemaining(
              child: Center(
                child: Text('An error occurred'),
              ),
            );
          } else if (snapshot.data == null) {
            return const SliverFillRemaining(
              child: Center(
                child: Text('No auctions available'),
              ),
            );
          } else if (snapshot.hasData) {
            final docs = snapshot.data![widget.auctionUid];
            final product = docs['itemInfo'];
            final admin = docs['adminInfo'];
            var bidders = docs['bidUid'].entries.toList();
            // sort the bidders by the highest bid
            bidders.sort((a, b) =>
                (b.value['bid'] as int).compareTo(a.value['bid'] as int));
            print('listahan: $bidders');

            var countdown = Countdown.getCountdownString(
                int.parse(docs['epochStart']), int.parse(docs['epochEnd']));

            return Stack(children: <Widget>[
              // add floating action button

              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                slivers: [
                  SliverAppBar.large(
                    automaticallyImplyLeading: false,
                    expandedHeight: 300,
                    pinned: true,
                    title: null,
                    centerTitle: true,
                    flexibleSpace: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        Builder(builder: (BuildContext context) {
                          return FlexibleSpaceBar(
                            background: CarouselWidget(
                              indicatorVisible: false,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(0)),
                              images: product['images'].cast<String>(),
                              internetFiles: true,
                            ),
                          );
                        }),
                        ValueListenableBuilder(
                            valueListenable: _isAppBarCollapsed,
                            builder: (BuildContext context, bool value,
                                Widget? child) {
                              return AnimatedOpacity(
                                opacity: value ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Theme.of(context)
                                            .scaffoldBackgroundColor
                                            .withAlpha(0),
                                        Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(
                                    FluentIcons.arrow_left_24_regular),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 270,
                                child: FlexibleSpaceBar(
                                  background: null,
                                  expandedTitleScale: 1.75,
                                  titlePadding:
                                      const EdgeInsets.only(bottom: 10),
                                  title: Text(
                                      toBeginningOfSentenceCase(
                                          product['item'] as String),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  centerTitle: true,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(FluentIcons.star_20_regular),
                                onPressed: () async {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Opacity(
                                        opacity: 0.7,
                                        child: Text('Seller',
                                            style: TextStyle(fontSize: 14.0))),
                                    const SizedBox(height: 10.0),
                                    Row(children: [
                                      CircleAvatar(
                                          radius: 22.0,
                                          backgroundColor: Colors.transparent,
                                          backgroundImage: NetworkImage(
                                              admin['thumbProfileImage'])),
                                      const SizedBox(width: 10.0),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                        // add a column to display the name and address of the seller
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${admin['firstName']} ${admin['middleName']} ${admin['lastName']}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 18.0,
                                              ),
                                            ),
                                            Text(
                                              admin['address'],
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ]),
                                  ]),
                              const SizedBox(width: 20.0),
                              countdown[0] == 'Auction ended'
                                  ? const SizedBox()
                                  : SizedBox(
                                      width: 110,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Opacity(
                                                opacity: 0.7,
                                                child: Text(countdown[0],
                                                    style: const TextStyle(
                                                        fontSize: 14.0))),
                                            const SizedBox(height: 10.0),
                                            Text(
                                              countdown[1]
                                                  .replaceFirst('d ', ' day\n'),
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                              ),
                                            ),
                                          ]),
                                    ),
                            ]),
                        const SizedBox(height: 30.0),
                        const Opacity(
                            opacity: 0.7,
                            child: Text('Description',
                                style: TextStyle(fontSize: 14.0))),
                        const SizedBox(height: 5.0),
                        Text(
                          product['description'],
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        const Opacity(
                            opacity: 0.7,
                            child: Text('Price',
                                style: TextStyle(fontSize: 14.0))),
                        const SizedBox(height: 5.0),
                        Text(
                          '₱${(product['price'] * 1.00).toStringAsFixed(2)} per item',
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        const Opacity(
                            opacity: 0.7,
                            child: Text('Quantity',
                                style: TextStyle(fontSize: 14.0))),
                        const SizedBox(height: 5.0),
                        Text(
                          '${product['quantity']}',
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        countdown[0] == 'Ends in'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Opacity(
                                        opacity: 0.7,
                                        child: Text('Highest Bid',
                                            style: TextStyle(fontSize: 14.0))),
                                    const SizedBox(height: 5.0),
                                    bidders.length > 0
                                        ? Column(
                                            children: [
                                              Card(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceTint,
                                                elevation: 10,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(8)),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      15.0),
                                                  child: Row(
                                                    children: <Widget>[
                                                      CircleAvatar(
                                                        radius: 25,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        backgroundImage:
                                                            NetworkImage(bidders
                                                                    .first
                                                                    .value[
                                                                'thumbProfileImage']),
                                                      ),
                                                      const SizedBox(
                                                          width: 15.0),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            bidders.first
                                                                .value['name'],
                                                            style: TextStyle(
                                                              fontSize: 18.0,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                            ),
                                                          ),
                                                          Opacity(
                                                            opacity: 0.8,
                                                            child: Text(
                                                              '₱${bidders.first.value['bid']}',
                                                              style: TextStyle(
                                                                fontSize: 14.0,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              ListView.builder(
                                                padding:
                                                    const EdgeInsets.all(0),
                                                shrinkWrap: true,
                                                itemCount: bidders.length - 1,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  var bidUser =
                                                      bidders[index + 1].value;
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        backgroundImage:
                                                            NetworkImage(bidUser[
                                                                'thumbProfileImage'])),
                                                    title: Text(bidUser['name'],
                                                        style: const TextStyle(
                                                            fontSize: 16.0,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)),
                                                    subtitle: Text(
                                                        '₱${bidUser['bid']}',
                                                        style: const TextStyle(
                                                            fontSize: 12.0)),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 25.0),
                                            ],
                                          )
                                        : const Text('No bids yet'),
                                  ])
                            : const SizedBox(),
                        const Opacity(
                            opacity: 0.7,
                            child: Text('Contacts',
                                style: TextStyle(fontSize: 14.0))),
                        const SizedBox(height: 5.0),
                        Row(
                          children: <Widget>[
                            Icon(
                              FluentIcons.call_16_filled,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 10.0),
                            Text(
                              '${admin['number']}',
                              style: const TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5.0),
                        Row(
                          children: <Widget>[
                            Icon(
                              FluentIcons.mail_16_filled,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 10.0),
                            Text(
                              '${admin['email']}',
                              style: const TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25.0),
                        Center(
                            child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/chat',
                              arguments: {
                                'chat': Chat(
                                  chat: chatDatabase.chatsMap,
                                  chatMembers: [
                                    docs['adminUid'],
                                    FirebaseAuth.instance.currentUser!.uid
                                  ],
                                ),
                                'from': context.findAncestorWidgetOfExactType<
                                    AuctionPage>()!,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            surfaceTintColor:
                                Theme.of(context).colorScheme.surfaceTint,
                            fixedSize: const Size(double.infinity, 50.0),
                          ),
                          icon: const Icon(FluentIcons.chat_16_filled),
                          label: const Text('Chat the seller'),
                        )),
                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom +
                                (countdown[0] == 'Ends in' ? 120.0 : 20.0)),
                      ],
                    ),
                  ))
                ],
              ),

              countdown[0] == 'Ends in'
                  ? Positioned(
                      bottom: 20 + MediaQuery.of(context).padding.bottom,
                      right: 20,
                      // fill the width of the screen
                      width: MediaQuery.of(context).size.width - 40,
                      child: Card.filled(
                        surfaceTintColor:
                            Theme.of(context).colorScheme.surfaceTint,
                        elevation: 20,
                        // set border radius
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(40)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  controller: _bidController,
                                  decoration: InputDecoration(
                                    prefixIcon: Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        child: Text('₱',
                                            style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                    fontSize: 20)
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w300))),
                                    filled: true,
                                    border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                          topLeft: Radius.circular(30),
                                          bottomLeft: Radius.circular(30),
                                        ),
                                        borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 55,
                                child: FilledButton(
                                  style: ButtonStyle(
                                    shape: WidgetStateProperty.all(
                                      const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(30),
                                        bottomRight: Radius.circular(30),
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      )),
                                    ),
                                  ),
                                  onPressed: () {
                                    final newRef = FirebaseFirestore.instance
                                        .collection('auctions')
                                        .doc(widget.auctionUid)
                                        .collection('bidUid');

                                    // check if the user has already placed a bid
                                    newRef.get().then((value) {
                                      final auctionRef = FirebaseFirestore
                                          .instance
                                          .collection('auctions')
                                          .doc(widget.auctionUid);

                                      // check if the user has already placed a bid
                                      for (var doc in value.docs) {
                                        print('value: ${doc.data()}');

                                        if (doc.data()['userUid'] ==
                                            FirebaseAuth
                                                .instance.currentUser!.uid) {
                                          newRef.doc(doc.id).update({
                                            'bid':
                                                int.parse(_bidController.text),
                                          });

                                          return;
                                        }
                                      }

                                      if (_bidController.text.isEmpty) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text('Error'),
                                              content: const Text(
                                                  'Please enter a bid'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Ok'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        return;
                                      }

                                      newRef.doc().set({
                                        'bid': int.parse(_bidController.text),
                                        'userUid': FirebaseAuth
                                            .instance.currentUser!.uid,
                                      });
                                    });
                                  },
                                  child: const Text('Place a Bid'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ]);
          }

          return const SliverFillRemaining(
            child: Center(
              child: Text('No auctions available'),
            ),
          );
        },
      ),
    );
  }
}
